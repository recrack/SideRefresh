# Contributing to SideRefresh

SideRefresh is a safety-sensitive developer tool: execute mode can build, sign,
and replace an app on a real iPhone. Contributions should keep user intent and
the exact target visible.

## Set up

Requirements:

- macOS 13 or later;
- Xcode 16.2 or a compatible Swift 6 toolchain;
- Python 3.10 or later for the legacy preflight tests.

Install the pinned Python test tool:

```sh
python3 -m pip install -r requirements-dev.txt
```

Install the repository-managed Git hooks once after cloning:

```sh
Scripts/install-git-hooks.sh
```

The pre-commit hook checks the staged diff and runs `swift test` only when
Swift package files changed. The pre-push hook runs the public-source checks,
Python and Swift tests, sample and Headless validation, and public-site/asset
validation.

Run the non-mutating checks from the repository root:

```sh
Scripts/test-public-source-validator.sh
Scripts/validate-public-source.sh
python3 -m pytest
swift test
Scripts/validate-samples.sh
Scripts/validate-headless.sh
Scripts/validate-product-hunt-assets.sh
Scripts/validate-product-hunt-site.sh
Scripts/test-public-site-validator.sh
```

`Scripts/validate-samples.sh` builds only for the iOS Simulator with code
signing disabled. It exercises the device helper in `--dry-run` mode and does
not install an app, register a Login Item, or change Tailscale.

## Make a change

1. Keep changes focused and explain the user-visible behavior.
2. Add or update tests for core scheduling, parsing, validation, and process
   behavior.
3. Preserve `--dry-run` as the default for the iOS helper.
4. Keep device identity, connection address, Xcode container, scheme, and
   expected Bundle ID as separate concepts.
5. Do not add automatic credential collection, Tailscale login, Developer Mode
   changes, pairing automation, or implicit Login Item registration.
6. Run all checks above before opening a pull request.

Local hooks provide early feedback but do not replace pull-request CI. Hooks
can be bypassed, while CI verifies the pushed commit in a clean GitHub-hosted
macOS environment.

Real-device testing is welcome, but a pull request must state exactly what was
tested: USB, local Wi-Fi, Tailscale, or another path. Do not describe a
cellular-only path as supported without a reproducible successful install.

Use [SUPPORT.md](SUPPORT.md) for help and follow the
[Code of Conduct](CODE_OF_CONDUCT.md) in every project space. Report security
problems through the private route in [SECURITY.md](SECURITY.md), never through
a public issue.

## Project structure

- `Sources/SideRefreshApp`: SwiftUI menu-bar app and settings.
- `Sources/SideRefreshAgent`: short-lived scheduled process.
- `Sources/SideRefreshCore`: renewal, process, project, and Tailnet logic.
- `Sources/SideRefreshIOSRenewal`: Xcode build and CoreDevice install helper.
- `Sources/SideRefreshCLI`: diagnostics and scripting entry point.
- `Sources/SideRefreshMCPServer`: headless MCP tools and stdio protocol.
- `Sources/SideRefreshMCP`: installed MCP server entry point.
- `Examples/SideRefreshSampleApp`: native iOS verification app.

## License

By contributing, you agree that your contribution is licensed under the
project's MIT License.
