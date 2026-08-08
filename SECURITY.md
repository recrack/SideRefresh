# Security policy

## Supported versions

SideRefresh is pre-1.0. Security fixes are applied to the latest source
prerelease and the default branch. `v0.2.0-beta.2` is source-only; there are no
supported binary release channels yet.

## Reporting a vulnerability

Do not include Apple credentials, signing material, device identifiers,
Tailnet addresses, project source, or other private data in a public issue.

Use [GitHub private vulnerability reporting](https://github.com/recrack/SideRefresh/security/advisories/new)
for a sensitive report. Include:

- the affected revision;
- the smallest reproducible configuration with secrets removed;
- whether `--execute` was used;
- the expected and observed security boundary;
- any relevant macOS, Xcode, and iOS versions.

For non-sensitive hardening suggestions, open a normal issue.

## Security boundaries

SideRefresh does not store Apple passwords or private signing keys. It delegates
signing and provisioning to Xcode, invokes commands directly without a shell,
requires an exact bundled helper for guided renewal, verifies the built Bundle
ID before installation, and records a renewal only after the command succeeds.

Treat configurations, logs, and Derived Data as sensitive: they may contain
project paths, device identifiers, team identifiers, and build output.
