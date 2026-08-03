"""Public CLI behavior for the opt-in Tailnet preflight tool."""

from __future__ import annotations

import json
import os
import plistlib
import subprocess
import sys
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def run_cli(*args: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    command_env = os.environ.copy()
    command_env["PYTHONPATH"] = str(ROOT)
    if env:
        command_env.update(env)
    return subprocess.run(
        [sys.executable, "-m", "ios_tailnet_preflight", *args],
        cwd=ROOT,
        env=command_env,
        text=True,
        capture_output=True,
        check=False,
    )


def start_cli(*args: str) -> subprocess.Popen[str]:
    command_env = os.environ.copy()
    command_env["PYTHONPATH"] = str(ROOT)
    return subprocess.Popen(
        [sys.executable, "-m", "ios_tailnet_preflight", *args],
        cwd=ROOT,
        env=command_env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def write_status_fixture(tmp_path: Path) -> Path:
    status = {
        "Self": {
            "HostName": "build-mac",
            "DNSName": "build-mac.example.ts.net.",
            "OS": "macOS",
            "TailscaleIPs": ["100.64.0.10"],
        },
        "Peer": {
            "peer-iphone": {
                "HostName": "test-iphone",
                "DNSName": "test-iphone.example.ts.net.",
                "OS": "iOS",
                "TailscaleIPs": ["100.64.0.42", "fd7a:115c:a1e0::42"],
            }
        },
    }
    path = tmp_path / "status.json"
    path.write_text(json.dumps(status), encoding="utf-8")
    return path


def test_discover_selects_an_ios_device_from_user_supplied_status_json(tmp_path: Path) -> None:
    status_path = write_status_fixture(tmp_path)

    result = run_cli(
        "discover",
        "--status-json",
        str(status_path),
        "--device",
        "test-iphone",
    )

    assert result.returncode == 0
    payload = json.loads(result.stdout)
    assert payload["selected_device"] == {
        "hostname": "test-iphone",
        "os": "iOS",
        "tailscale_ips": ["100.64.0.42", "fd7a:115c:a1e0::42"],
    }
    assert payload["system_changes_performed"] is False


def test_discover_refuses_to_read_tailscale_without_explicit_approval() -> None:
    result = run_cli("discover")

    assert result.returncode == 2
    assert "--status-json" in result.stderr
    assert "--read-tailscale-status" in result.stderr


def test_preflight_only_prints_the_manual_xcode_steps() -> None:
    result = run_cli(
        "preflight",
        "--tailnet-ip",
        "100.64.0.42",
        "--device",
        "test-iphone",
    )

    assert result.returncode == 0
    payload = json.loads(result.stdout)
    assert payload["system_changes_performed"] is False
    assert payload["tailnet_ip"] == "100.64.0.42"
    assert payload["manual_xcode_step"] == "Devices and Simulators → Connect via IP Address"


def test_preflight_rejects_an_invalid_ip_address() -> None:
    result = run_cli("preflight", "--tailnet-ip", "not-an-ip")

    assert result.returncode == 2
    assert "valid IP address" in result.stderr


def test_renewal_status_reports_a_missing_state_as_due_without_creating_it(
    tmp_path: Path,
) -> None:
    state_path = tmp_path / "renewal-state.json"

    result = run_cli("renewal", "status", "--state-file", str(state_path))

    assert result.returncode == 0
    payload = json.loads(result.stdout)
    assert payload == {
        "due": True,
        "last_successful_renewal": None,
        "next_due": None,
        "renew_every_hours": 144,
        "state_file": str(state_path),
        "system_changes_performed": False,
    }
    assert not state_path.exists()


def test_run_due_executes_the_renewal_command_once_and_records_success(
    tmp_path: Path,
) -> None:
    state_path = tmp_path / "renewal-state.json"
    marker_path = tmp_path / "renewed.txt"
    command = (
        "from pathlib import Path; "
        f"Path({str(marker_path)!r}).write_text('renewed', encoding='utf-8')"
    )

    first = run_cli(
        "renewal",
        "run-due",
        "--state-file",
        str(state_path),
        "--",
        sys.executable,
        "-c",
        command,
    )
    second = run_cli(
        "renewal",
        "run-due",
        "--state-file",
        str(state_path),
        "--",
        sys.executable,
        "-c",
        command,
    )

    assert first.returncode == 0
    first_payload = json.loads(first.stdout)
    assert first_payload["renewal_command_executed"] is True
    assert first_payload["renewal_succeeded"] is True
    assert first_payload["state_updated"] is True
    assert marker_path.read_text(encoding="utf-8") == "renewed"

    assert second.returncode == 0
    second_payload = json.loads(second.stdout)
    assert second_payload["due"] is False
    assert second_payload["renewal_command_executed"] is False
    assert second_payload["state_updated"] is False


def test_generate_launch_agent_writes_a_background_schedule_without_registering_it(
    tmp_path: Path,
) -> None:
    plist_path = tmp_path / "io.github.ios-tailnet-preflight.renewal.plist"
    state_path = tmp_path / "renewal-state.json"

    result = run_cli(
        "renewal",
        "generate-launch-agent",
        "--output",
        str(plist_path),
        "--state-file",
        str(state_path),
        "--run-every-seconds",
        "21600",
        "--",
        sys.executable,
        "-c",
        "raise SystemExit(0)",
    )

    assert result.returncode == 0
    payload = json.loads(result.stdout)
    assert payload["launch_agent_generated"] is True
    assert payload["scheduler_registration_performed"] is False

    with plist_path.open("rb") as plist_file:
        launch_agent = plistlib.load(plist_file)
    assert launch_agent["Label"] == "io.github.ios-tailnet-preflight.renewal"
    assert launch_agent["RunAtLoad"] is True
    assert launch_agent["StartInterval"] == 21600
    assert launch_agent["ProgramArguments"][-3:] == [
        sys.executable,
        "-c",
        "raise SystemExit(0)",
    ]
    assert "KeepAlive" not in launch_agent


def test_concurrent_run_due_commands_only_execute_one_renewal(tmp_path: Path) -> None:
    state_path = tmp_path / "renewal-state.json"
    marker_path = tmp_path / "renewals.txt"
    command = (
        "import time; "
        f"marker = open({str(marker_path)!r}, 'a', encoding='utf-8'); "
        "marker.write('renewed\\n'); marker.close(); time.sleep(0.5)"
    )
    invocation = (
        "renewal",
        "run-due",
        "--state-file",
        str(state_path),
        "--",
        sys.executable,
        "-c",
        command,
    )

    first = start_cli(*invocation)
    second = start_cli(*invocation)
    first_stdout, first_stderr = first.communicate(timeout=10)
    second_stdout, second_stderr = second.communicate(timeout=10)

    assert first.returncode == 0, first_stderr
    assert second.returncode == 0, second_stderr
    payloads = [json.loads(first_stdout), json.loads(second_stdout)]
    assert sorted(payload["renewal_command_executed"] for payload in payloads) == [
        False,
        True,
    ]
    assert marker_path.read_text(encoding="utf-8") == "renewed\n"


def test_run_due_bounds_the_command_output_kept_in_memory(tmp_path: Path) -> None:
    state_path = tmp_path / "renewal-state.json"
    result = run_cli(
        "renewal",
        "run-due",
        "--state-file",
        str(state_path),
        "--",
        sys.executable,
        "-c",
        "import sys; print('x' * 70000); print('y' * 70000, file=sys.stderr)",
    )

    assert result.returncode == 0
    payload = json.loads(result.stdout)
    assert payload["renewal_command_stdout_truncated"] is True
    assert "earlier bytes omitted" in payload["renewal_command_stdout"]
    assert len(payload["renewal_command_stdout"]) < 66000
    assert payload["renewal_command_stderr_truncated"] is True
    assert "earlier bytes omitted" in payload["renewal_command_stderr"]
    assert len(payload["renewal_command_stderr"]) < 66000


def test_run_due_does_not_wait_indefinitely_for_a_descendant_holding_log_pipes(
    tmp_path: Path,
) -> None:
    state_path = tmp_path / "renewal-state.json"
    command = (
        "import subprocess, sys; "
        "subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(3)'])"
    )

    started_at = time.monotonic()
    result = run_cli(
        "renewal",
        "run-due",
        "--state-file",
        str(state_path),
        "--",
        sys.executable,
        "-c",
        command,
    )
    elapsed = time.monotonic() - started_at

    assert result.returncode == 0
    assert elapsed < 2
