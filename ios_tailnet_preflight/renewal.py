"""Renewal scheduling state for background Personal Team refreshes."""

from __future__ import annotations

import json
import os
import plistlib
import tempfile
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Iterator

import fcntl


DEFAULT_RENEW_EVERY_HOURS = 6 * 24
DEFAULT_RUN_EVERY_SECONDS = 6 * 60 * 60
DEFAULT_LAUNCH_AGENT_LABEL = "io.github.ios-tailnet-preflight.renewal"


def read_last_successful_renewal(state_file: Path) -> datetime | None:
    if not state_file.exists():
        return None

    try:
        value: Any = json.loads(state_file.read_text(encoding="utf-8"))
    except OSError as error:
        raise ValueError(f"could not read renewal state: {error}") from error
    except json.JSONDecodeError as error:
        raise ValueError(f"renewal state is invalid JSON: {error.msg}") from error

    if not isinstance(value, dict):
        raise ValueError("renewal state must contain an object")
    timestamp = value.get("last_successful_renewal")
    if not isinstance(timestamp, str):
        raise ValueError("renewal state is missing last_successful_renewal")
    try:
        parsed = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
    except ValueError as error:
        raise ValueError("last_successful_renewal must be an ISO 8601 timestamp") from error
    if parsed.tzinfo is None:
        raise ValueError("last_successful_renewal must include a timezone")
    return parsed.astimezone(timezone.utc)


def renewal_status(
    state_file: Path,
    *,
    renew_every_hours: int = DEFAULT_RENEW_EVERY_HOURS,
    now: datetime | None = None,
) -> dict[str, Any]:
    last_success = read_last_successful_renewal(state_file)
    if last_success is None:
        due = True
        next_due = None
    else:
        next_due_at = last_success + timedelta(hours=renew_every_hours)
        current_time = now or datetime.now(timezone.utc)
        due = current_time >= next_due_at
        next_due = next_due_at.isoformat().replace("+00:00", "Z")

    return {
        "due": due,
        "last_successful_renewal": (
            last_success.isoformat().replace("+00:00", "Z") if last_success else None
        ),
        "next_due": next_due,
        "renew_every_hours": renew_every_hours,
        "state_file": str(state_file),
        "system_changes_performed": False,
    }


def record_successful_renewal(
    state_file: Path, completed_at: datetime | None = None
) -> str:
    timestamp = (completed_at or datetime.now(timezone.utc)).astimezone(timezone.utc)
    encoded_timestamp = timestamp.isoformat().replace("+00:00", "Z")
    payload = {
        "schema_version": 1,
        "last_successful_renewal": encoded_timestamp,
    }

    temporary_name: str | None = None
    try:
        state_file.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=state_file.parent,
            prefix=f".{state_file.name}.",
            suffix=".tmp",
            delete=False,
        ) as temporary:
            temporary_name = temporary.name
            json.dump(payload, temporary, indent=2, sort_keys=True)
            temporary.write("\n")
        os.chmod(temporary_name, 0o600)
        os.replace(temporary_name, state_file)
    except OSError as error:
        if temporary_name is not None:
            try:
                Path(temporary_name).unlink(missing_ok=True)
            except OSError:
                pass
        raise ValueError(f"could not write renewal state: {error}") from error

    return encoded_timestamp


@contextmanager
def renewal_lock(state_file: Path) -> Iterator[Path]:
    """Serialize check/run/write transactions that share a renewal state file."""
    lock_file_path = state_file.with_name(f"{state_file.name}.lock")
    lock_file = None
    try:
        lock_file_path.parent.mkdir(parents=True, exist_ok=True)
        lock_file = lock_file_path.open("a+", encoding="utf-8")
        os.chmod(lock_file_path, 0o600)
        fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
    except OSError as error:
        if lock_file is not None:
            lock_file.close()
        raise ValueError(f"could not acquire renewal lock: {error}") from error

    try:
        yield lock_file_path
    finally:
        try:
            fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)
        finally:
            lock_file.close()


def write_launch_agent(
    output: Path,
    *,
    state_file: Path,
    renewal_command: list[str],
    project_root: Path,
    python_executable: Path,
    renew_every_hours: int = DEFAULT_RENEW_EVERY_HOURS,
    run_every_seconds: int = DEFAULT_RUN_EVERY_SECONDS,
    label: str = DEFAULT_LAUNCH_AGENT_LABEL,
    overwrite: bool = False,
) -> None:
    if output.exists() and not overwrite:
        raise ValueError(
            f"launch agent file already exists: {output}; pass --force to replace it"
        )

    launch_agent = {
        "Label": label,
        "ProgramArguments": [
            str(python_executable),
            "-m",
            "ios_tailnet_preflight",
            "renewal",
            "run-due",
            "--state-file",
            str(state_file),
            "--renew-every-hours",
            str(renew_every_hours),
            "--",
            *renewal_command,
        ],
        "RunAtLoad": True,
        "StartInterval": run_every_seconds,
        "WorkingDirectory": str(project_root),
        "EnvironmentVariables": {"PYTHONPATH": str(project_root)},
        "ProcessType": "Background",
    }
    encoded = plistlib.dumps(launch_agent, fmt=plistlib.FMT_XML, sort_keys=True)
    try:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(encoded)
    except OSError as error:
        raise ValueError(f"could not write launch agent file: {error}") from error
