# SideRefresh support

## Setup and usage

Start with the [English manual](docs/MANUAL.md) or
[한국어 설명서](docs/MANUAL.ko.md). Signing and provisioning problems are covered
in the [Personal Team setup guide](docs/PERSONAL-TEAM-SETUP.md).

## Ask for help

Search existing issues before opening a new one. For a reproducible product
problem, use the bug-report form and include:

- SideRefresh revision or version;
- macOS, Xcode, and iOS versions;
- whether the route was USB, local Wi-Fi, or experimental Tailscale;
- the smallest sequence that reproduces the problem; and
- sanitized logs with paths, device IDs, team IDs, and account data removed.

General feature proposals belong in the feature-request form. SideRefresh is a
community-maintained open-source project, so response times are not guaranteed.

## Sensitive reports

Do not put credentials, signing material, device identifiers, Tailnet names,
private project paths, or source code in a public issue. Follow
[SECURITY.md](SECURITY.md) and use GitHub private vulnerability reporting for a
security problem.

## Distribution status

Source builds are supported for contributors. A Developer ID-signed and
notarized public Mac archive remains a separate release gate; check
[distribution status](docs/DISTRIBUTION.md) before assuming a binary is ready.
