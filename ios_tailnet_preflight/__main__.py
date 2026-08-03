"""CLI for Tailnet device discovery, Xcode guidance, and renewal scheduling."""

from __future__ import annotations

import argparse
import ipaddress
import json
import os
import selectors
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

from .renewal import (
    DEFAULT_LAUNCH_AGENT_LABEL,
    DEFAULT_RENEW_EVERY_HOURS,
    DEFAULT_RUN_EVERY_SECONDS,
    record_successful_renewal,
    renewal_lock,
    renewal_status,
    write_launch_agent,
)

MAX_CAPTURED_COMMAND_OUTPUT_BYTES = 64 * 1024
PIPE_DRAIN_GRACE_SECONDS = 0.5


def tailnet_devices(status: dict[str, Any]) -> list[dict[str, Any]]:
    """Return iOS-family devices from a Tailscale status document."""
    records: list[dict[str, Any]] = []
    self_record = status.get("Self")
    if isinstance(self_record, dict):
        records.append(self_record)

    peers = status.get("Peer", {})
    if isinstance(peers, dict):
        records.extend(peer for peer in peers.values() if isinstance(peer, dict))

    devices = []
    for record in records:
        os_name = str(record.get("OS", ""))
        if os_name.casefold() not in {"ios", "ipados"}:
            continue
        ips = record.get("TailscaleIPs", [])
        if not isinstance(ips, list):
            ips = []
        devices.append(
            {
                "hostname": str(record.get("HostName", "")),
                "os": os_name,
                "tailscale_ips": [str(address) for address in ips],
            }
        )
    return devices


def select_device(devices: list[dict[str, Any]], requested_name: str | None) -> dict[str, Any] | None:
    """Select a device only when the user supplied an unambiguous name."""
    if requested_name is None:
        return None

    matches = [
        device
        for device in devices
        if device["hostname"].casefold() == requested_name.casefold()
    ]
    if len(matches) != 1:
        raise ValueError(f"no unique iOS/iPadOS Tailnet device named {requested_name!r}")
    return matches[0]


def read_status_file(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except OSError as error:
        raise ValueError(f"could not read status JSON: {error}") from error
    except json.JSONDecodeError as error:
        raise ValueError(f"status JSON is invalid: {error.msg}") from error
    if not isinstance(value, dict):
        raise ValueError("status JSON must contain an object")
    return value


def read_status_from_cli(command: str) -> dict[str, Any]:
    """Read status only after the caller explicitly opted into the CLI call."""
    try:
        result = subprocess.run(
            [command, "status", "--json"],
            text=True,
            capture_output=True,
            check=False,
        )
    except OSError as error:
        raise ValueError(f"could not run {command!r}: {error}") from error
    if result.returncode != 0:
        detail = result.stderr.strip() or "no error output"
        raise ValueError(f"{command!r} status failed: {detail}")
    try:
        value = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise ValueError(f"{command!r} did not return JSON: {error.msg}") from error
    if not isinstance(value, dict):
        raise ValueError(f"{command!r} did not return a JSON object")
    return value


def discover(args: argparse.Namespace, parser: argparse.ArgumentParser) -> int:
    if args.status_json:
        status = read_status_file(Path(args.status_json))
        source = "user-supplied-status-file"
    elif args.read_tailscale_status:
        status = read_status_from_cli(args.tailscale_command)
        source = "user-approved-tailscale-cli"
    else:
        parser.error(
            "discovery is read-only but opt-in: pass --status-json FILE or --read-tailscale-status"
        )

    devices = tailnet_devices(status)
    try:
        selected = select_device(devices, args.device)
    except ValueError as error:
        parser.error(str(error))

    print(
        json.dumps(
            {
                "source": source,
                "devices": devices,
                "selected_device": selected,
                "system_changes_performed": False,
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


def preflight(args: argparse.Namespace, parser: argparse.ArgumentParser) -> int:
    try:
        address = ipaddress.ip_address(args.tailnet_ip)
    except ValueError:
        parser.error("--tailnet-ip must be a valid IP address")

    print(
        json.dumps(
            {
                "device": args.device,
                "tailnet_ip": str(address),
                "manual_xcode_step": "Devices and Simulators → Connect via IP Address",
                "next_actions": [
                    "On the iPhone, keep Tailscale connected using the user-chosen VPN On Demand policy.",
                    "In Xcode, select the already-paired device and choose Connect via IP Address.",
                    "Enter this IP yourself, then decide whether to run Build & Run.",
                ],
                "system_changes_performed": False,
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


def renewal_status_command(
    args: argparse.Namespace, parser: argparse.ArgumentParser
) -> int:
    del parser
    payload = renewal_status(
        Path(args.state_file), renew_every_hours=args.renew_every_hours
    )
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 0


def explicit_command(
    raw_command: list[str], parser: argparse.ArgumentParser, action: str
) -> list[str]:
    command = list(raw_command)
    if command and command[0] == "--":
        command = command[1:]
    if not command:
        parser.error(f"{action} requires a renewal command after `--`")
    return command


def decoded_tail(tail: bytearray, total_bytes: int) -> tuple[str, bool]:
    truncated = total_bytes > MAX_CAPTURED_COMMAND_OUTPUT_BYTES
    output = bytes(tail).decode("utf-8", errors="replace")
    if truncated:
        omitted = total_bytes - MAX_CAPTURED_COMMAND_OUTPUT_BYTES
        output = f"[{omitted} earlier bytes omitted]\n{output}"
    return output, truncated


def captured_command(command: list[str]) -> tuple[int, str, str, bool, bool]:
    try:
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except OSError as error:
        raise ValueError(f"could not run renewal command: {error}") from error

    if process.stdout is None or process.stderr is None:
        process.kill()
        raise ValueError("could not capture renewal command output")

    streams = {
        "stdout": process.stdout,
        "stderr": process.stderr,
    }
    tails = {
        "stdout": bytearray(),
        "stderr": bytearray(),
    }
    totals = {
        "stdout": 0,
        "stderr": 0,
    }
    selector = selectors.DefaultSelector()
    try:
        for name, stream in streams.items():
            os.set_blocking(stream.fileno(), False)
            selector.register(stream, selectors.EVENT_READ, data=name)

        drain_deadline: float | None = None
        while selector.get_map():
            if process.poll() is not None:
                if drain_deadline is None:
                    drain_deadline = time.monotonic() + PIPE_DRAIN_GRACE_SECONDS
                remaining = drain_deadline - time.monotonic()
                if remaining <= 0:
                    break
                timeout = min(0.1, remaining)
            else:
                timeout = 0.1

            for key, _ in selector.select(timeout):
                stream = key.fileobj
                try:
                    chunk = os.read(stream.fileno(), 8192)
                except BlockingIOError:
                    continue
                if not chunk:
                    selector.unregister(stream)
                    stream.close()
                    continue

                name = key.data
                totals[name] += len(chunk)
                tails[name].extend(chunk)
                if len(tails[name]) > MAX_CAPTURED_COMMAND_OUTPUT_BYTES:
                    del tails[name][:-MAX_CAPTURED_COMMAND_OUTPUT_BYTES]

        return_code = process.wait()
    except OSError as error:
        if process.poll() is None:
            process.kill()
            process.wait()
        raise ValueError(f"could not capture renewal command output: {error}") from error
    finally:
        selector.close()
        for stream in streams.values():
            if not stream.closed:
                stream.close()

    stdout, stdout_truncated = decoded_tail(tails["stdout"], totals["stdout"])
    stderr, stderr_truncated = decoded_tail(tails["stderr"], totals["stderr"])
    return return_code, stdout, stderr, stdout_truncated, stderr_truncated


def run_due_command(args: argparse.Namespace, parser: argparse.ArgumentParser) -> int:
    command = explicit_command(args.renew_command, parser, "run-due")
    state_file = Path(args.state_file)

    with renewal_lock(state_file) as lock_file:
        payload = renewal_status(
            state_file, renew_every_hours=args.renew_every_hours
        )
        payload.update(
            {
                "lock_file": str(lock_file),
                "renewal_command_executed": False,
                "renewal_succeeded": None,
                "state_updated": False,
                "scheduler_registration_performed": False,
            }
        )
        if not payload["due"]:
            print(json.dumps(payload, indent=2, sort_keys=True))
            return 0

        return_code, stdout, stderr, stdout_truncated, stderr_truncated = (
            captured_command(command)
        )

        payload.update(
            {
                "renewal_command_executed": True,
                "renewal_succeeded": return_code == 0,
                "renewal_command_exit_code": return_code,
                "renewal_command_stdout": stdout,
                "renewal_command_stderr": stderr,
                "renewal_command_stdout_truncated": stdout_truncated,
                "renewal_command_stderr_truncated": stderr_truncated,
                "system_changes_performed": True,
            }
        )
        if return_code == 0:
            record_successful_renewal(state_file)
            updated_status = renewal_status(
                state_file, renew_every_hours=args.renew_every_hours
            )
            payload.update(
                {
                    "due": updated_status["due"],
                    "last_successful_renewal": updated_status[
                        "last_successful_renewal"
                    ],
                    "next_due": updated_status["next_due"],
                    "state_updated": True,
                }
            )

        print(json.dumps(payload, indent=2, sort_keys=True))
        return return_code


def generate_launch_agent_command(
    args: argparse.Namespace, parser: argparse.ArgumentParser
) -> int:
    command = explicit_command(
        args.renew_command, parser, "generate-launch-agent"
    )

    output = Path(args.output)
    write_launch_agent(
        output,
        state_file=Path(args.state_file).resolve(),
        renewal_command=command,
        project_root=Path(args.project_root).resolve(),
        python_executable=Path(args.python_executable).resolve(),
        renew_every_hours=args.renew_every_hours,
        run_every_seconds=args.run_every_seconds,
        label=args.label,
        overwrite=args.force,
    )
    print(
        json.dumps(
            {
                "launch_agent_file": str(output),
                "launch_agent_generated": True,
                "scheduler_registration_performed": False,
                "system_changes_performed": True,
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


def positive_integer(value: str) -> int:
    parsed = int(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("must be greater than zero")
    return parsed


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="ios-tailnet-preflight",
        description="Read-only Tailnet discovery and Xcode direct-IP PoC guidance.",
    )
    subcommands = parser.add_subparsers(dest="command", required=True)

    discover_parser = subcommands.add_parser(
        "discover", help="list iOS/iPadOS Tailnet devices from explicit status input"
    )
    source = discover_parser.add_mutually_exclusive_group()
    source.add_argument("--status-json", help="a Tailscale status JSON file supplied by the user")
    source.add_argument(
        "--read-tailscale-status",
        action="store_true",
        help="explicitly run `tailscale status --json` using the command below",
    )
    discover_parser.add_argument(
        "--tailscale-command",
        default="tailscale",
        help="Tailscale CLI executable; used only with --read-tailscale-status",
    )
    discover_parser.add_argument("--device", help="the iOS/iPadOS Tailnet hostname to select")
    discover_parser.set_defaults(handler=discover)

    preflight_parser = subcommands.add_parser(
        "preflight", help="print manual Xcode direct-IP PoC instructions"
    )
    preflight_parser.add_argument("--tailnet-ip", required=True, help="the user-selected iPhone Tailnet IP")
    preflight_parser.add_argument("--device", help="optional display name for the paired iPhone")
    preflight_parser.set_defaults(handler=preflight)

    renewal_parser = subcommands.add_parser(
        "renewal", help="manage background renewal timing without keeping a terminal open"
    )
    renewal_subcommands = renewal_parser.add_subparsers(
        dest="renewal_command", required=True
    )
    renewal_status_parser = renewal_subcommands.add_parser(
        "status", help="show whether renewal is due without changing state"
    )
    renewal_status_parser.add_argument(
        "--state-file", required=True, help="renewal state JSON path"
    )
    renewal_status_parser.add_argument(
        "--renew-every-hours",
        type=positive_integer,
        default=DEFAULT_RENEW_EVERY_HOURS,
        help="renewal interval; defaults to six days (144 hours)",
    )
    renewal_status_parser.set_defaults(handler=renewal_status_command)

    run_due_parser = renewal_subcommands.add_parser(
        "run-due", help="run an explicit renewal command only when renewal is due"
    )
    run_due_parser.add_argument(
        "--state-file", required=True, help="renewal state JSON path"
    )
    run_due_parser.add_argument(
        "--renew-every-hours",
        type=positive_integer,
        default=DEFAULT_RENEW_EVERY_HOURS,
        help="renewal interval; defaults to six days (144 hours)",
    )
    run_due_parser.add_argument(
        "renew_command",
        nargs=argparse.REMAINDER,
        help="command and arguments following `--`; executed without a shell",
    )
    run_due_parser.set_defaults(handler=run_due_command)

    generate_parser = renewal_subcommands.add_parser(
        "generate-launch-agent",
        help="generate, but do not register, a macOS background schedule",
    )
    generate_parser.add_argument(
        "--output", required=True, help="destination for the generated plist"
    )
    generate_parser.add_argument(
        "--state-file", required=True, help="renewal state JSON path"
    )
    generate_parser.add_argument(
        "--project-root",
        default=str(Path.cwd()),
        help="project root added to PYTHONPATH for source-tree execution",
    )
    generate_parser.add_argument(
        "--python-executable",
        default=sys.executable,
        help="Python executable used by the background job",
    )
    generate_parser.add_argument(
        "--renew-every-hours",
        type=positive_integer,
        default=DEFAULT_RENEW_EVERY_HOURS,
        help="renewal interval; defaults to six days (144 hours)",
    )
    generate_parser.add_argument(
        "--run-every-seconds",
        type=positive_integer,
        default=DEFAULT_RUN_EVERY_SECONDS,
        help="how often launchd checks whether renewal is due",
    )
    generate_parser.add_argument(
        "--label", default=DEFAULT_LAUNCH_AGENT_LABEL, help="launchd job label"
    )
    generate_parser.add_argument(
        "--force", action="store_true", help="replace an existing output file"
    )
    generate_parser.add_argument(
        "renew_command",
        nargs=argparse.REMAINDER,
        help="command and arguments following `--`; stored without a shell",
    )
    generate_parser.set_defaults(handler=generate_launch_agent_command)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return args.handler(args, parser)
    except ValueError as error:
        parser.error(str(error))
    return 2


if __name__ == "__main__":
    sys.exit(main())
