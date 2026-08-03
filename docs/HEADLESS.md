# SideRefresh CLI, LaunchAgent, and MCP

SideRefresh can run without the menu-bar app. The CLI and MCP server configure
and inspect renewals. The Helper and LaunchAgent perform the actual
Xcode/CoreDevice work.

## Install

Install the headless package:

```sh
Scripts/install-headless.sh
```

It contains:

- `side-refresh`;
- `SideRefreshAgent`;
- `SideRefreshIOSRenewal`; and
- the `siderefresh-mcp` stdio server.

The default installation root is:

```text
~/Library/Application Support/SideRefresh/Headless
```

Configuration and renewal receipts remain one directory above the binaries.
Replacing the headless binaries does not erase them.

The installer prints the exact MCP client configuration for the installed
path. A normal install does not enable scheduled renewal.

Optional installer arguments:

- `--install-root /absolute/path` changes the destination.
- `--skip-build` installs already built artifacts.
- `--enable-schedule` enables an existing execute-mode target.
- `--config /absolute/path/agent-config.json` selects the target used with
  `--enable-schedule`.

## Save a target

Save and review one target before enabling the schedule:

```sh
"/Users/YOU/Library/Application Support/SideRefresh/Headless/bin/side-refresh" \
  config save \
  --helper \
  "/Users/YOU/Library/Application Support/SideRefresh/Headless/bin/SideRefreshIOSRenewal" \
  --renew-every-hours 144 \
  --confirm-execute \
  -- \
  --execute \
  --container /absolute/path/App.xcodeproj \
  --scheme App \
  --configuration Release \
  --team YOUR_TEAM_ID \
  --bundle-id your.unique.bundle.identifier \
  --product App \
  --device YOUR_DEVICE_UDID \
  --derived-data /absolute/path/DerivedData \
  --build-strategy incremental \
  --version-policy keep
```

`--build-strategy` accepts `incremental` or `clean-rebuild`.

`--version-policy` accepts `keep` or `automatic`. See the
[iOS renewal helper guide](IOS-RENEWAL.md) for the canonical build and version
rules.

The renewal interval accepts 1 through 168 hours and defaults to 144.
`--state-file` can select an absolute receipt path. The helper build
configuration defaults to `Release`.

Inspect the saved target and due state without changing them:

```sh
"/Users/YOU/Library/Application Support/SideRefresh/Headless/bin/side-refresh" \
  config show

"/Users/YOU/Library/Application Support/SideRefresh/Headless/bin/side-refresh" \
  renewal status-config
```

## Enable and operate the schedule

Explicitly enable the user LaunchAgent:

```sh
"/Users/YOU/Library/Application Support/SideRefresh/Headless/bin/side-refresh" \
  schedule enable \
  --agent \
  "/Users/YOU/Library/Application Support/SideRefresh/Headless/bin/SideRefreshAgent" \
  --confirm
```

The Agent checks at 00:00, 06:00, 12:00, and 18:00, then exits. The menu-bar
app and MCP client do not need to remain open.

Operate the saved configuration:

```sh
# Perform a confirmed build, sign, and install now.
"/Users/YOU/Library/Application Support/SideRefresh/Headless/bin/side-refresh" \
  renewal run-now --confirm

# Read or disable the background schedule.
"/Users/YOU/Library/Application Support/SideRefresh/Headless/bin/side-refresh" \
  schedule status

"/Users/YOU/Library/Application Support/SideRefresh/Headless/bin/side-refresh" \
  schedule disable --confirm
```

Pass `--config /absolute/path/agent-config.json` to a configuration command
when using a non-default target file.

`renewal run-due-config` exposes the same due-only runner used by
`SideRefreshAgent`. Failed runs do not advance the successful-renewal receipt.

## Where automation runs

| Runner | Real iPhone renewal | SideRefresh role |
| --- | --- | --- |
| Local LaunchAgent | Supported | Scheduled build, sign, and install |
| GitHub-hosted macOS runner | Not supported | Pull-request validation only |
| Self-hosted runner on the prepared Mac | Possible, not configured | Optional external trigger |

GitHub provisions a fresh VM for each hosted job and removes it afterward.
That VM does not inherit the user's local project, signing Keychain, Xcode
pairing, or physical iPhone.

The checked-in workflow runs `swift test`, sample validation, and Headless/MCP
validation on `macos-15` for pull requests. It does not renew an app and does
not run again after merge.

A self-hosted runner on the same prepared Mac could invoke `side-refresh`.
SideRefresh does not register that runner or ship a renewal workflow. Keep a
self-hosted runner away from untrusted pull-request code, especially for a
public repository.

See GitHub's documentation for
[GitHub-hosted runner lifecycle](https://docs.github.com/en/actions/how-tos/manage-runners/github-hosted-runners/use-github-hosted-runners)
and
[self-hosted runner security](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners).

## Direct renewal CLI

Read the state for an exact command without changing it:

```sh
swift run side-refresh renewal status \
  --state-file ./var/renewal-state.json \
  -- /absolute/path/to/renew-command
```

Run it only when renewal is due:

```sh
swift run side-refresh renewal run-due \
  --state-file ./var/renewal-state.json \
  -- /absolute/path/to/renew-command
```

Both operations are scoped to the exact executable and ordered arguments after
`--`. A previous dry run cannot hide that a new execute command is due.

The command runs directly without a shell. Exit status zero records success.
A non-zero status leaves renewal state unchanged for a later retry.

## MCP server

`siderefresh-mcp` implements the MCP `2025-11-25` stdio transport.

Available tools:

- `get_status` reads the target, due state, and schedule state.
- `configure_target` saves or replaces one target.
- `dry_run` resolves the build/install plan without changing state.
- `renew_now` builds, signs, and installs immediately.
- `enable_schedule` installs and bootstraps the user LaunchAgent.
- `disable_schedule` removes the LaunchAgent while preserving configuration,
  binaries, and renewal state.

Confirmation rules:

- `configure_target` requires `confirm: true`.
- Execute mode also requires `confirm_execute: true`.
- `renew_now`, `enable_schedule`, and `disable_schedule` require
  `confirm: true`.
- `get_status` and `dry_run` are read-only.

`dry_run` forces dry-run mode for that invocation even if the saved target is
executable. It never updates renewal state.

`get_status` reports the scheduled configuration path and
`schedule_matches_configuration`. This prevents the state for one
configuration from being mistaken for another.

A Skill can teach an AI client how to call these tools, but it cannot replace
the installed Helper, Xcode, signing identity, or reachable iPhone.

### Protocol compatibility

This release supports the
[`2025-11-25`](https://modelcontextprotocol.io/specification/2025-11-25)
`initialize` and `initialized` lifecycle.

It does not implement the breaking `2026-07-28` stateless lifecycle. Clients
must retain or negotiate the supported revision.

### Client configuration

Example MCP client entry:

```json
{
  "mcpServers": {
    "siderefresh": {
      "command": "/Users/YOU/Library/Application Support/SideRefresh/Headless/bin/siderefresh-mcp"
    }
  }
}
```

For a custom default target file, add:

```json
"args": ["--config", "/absolute/path/agent-config.json"]
```

An individual MCP call can instead pass the absolute path as `config_path`.
A tool argument overrides the server default.

## Build without installing

Build a portable local headless directory:

```sh
Scripts/build-headless.sh
```

The output is:

```text
dist/SideRefreshHeadless
```

Xcode, an Apple Development identity, project source, and an already paired
and reachable iPhone remain required.

## Tailnet discovery

Parse the checked-in sample without invoking Tailscale:

```sh
swift run side-refresh tailnet discover \
  --status-file \
  "$PWD/Examples/Tailnet/tailscale-status.sample.json"
```

Read live state only after selecting the executable:

```sh
swift run side-refresh tailnet discover \
  --tailscale /absolute/path/to/tailscale
```

The command runs only `tailscale status --json`. It does not sign in, enable
Tailscale, change VPN preferences, or modify ACLs.

Tailnet addresses do not replace the CoreDevice UDID required for
installation.

## Agent bundle

The built app contains:

```text
SideRefresh.app/
└── Contents/
    ├── MacOS/SideRefresh
    ├── Resources/
    │   ├── SideRefreshAgent
    │   ├── SideRefreshIOSRenewal
    │   └── Samples/SideRefreshSampleApp/
    └── Library/LaunchAgents/io.github.siderefresh.renewal.plist
```

The plist uses `BundleProgram`, `RunAtLoad`, and four
`StartCalendarInterval` entries.

Calendar events missed during sleep are coalesced by `launchd` and run after
wake. The app calls `SMAppService.agent(plistName:)` only after confirmation.
