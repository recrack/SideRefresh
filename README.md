# SideRefresh — Automatic iOS App Refresh

<img src="Assets/Brand/SideRefresh-AppIcon-1024.png" alt="SideRefresh logo" width="144">

[English](README.md) | [한국어](README.ko.md)

**Keep agent-built iOS apps alive on your iPhone.**

개인용 iOS 앱 자동 갱신 도구 — Personal Team 앱을 만료 전에 다시
빌드하고 설치하세요.

SideRefresh is a native macOS tool for automatic iOS app refresh with a free
Xcode Personal Team. It rebuilds your current source, signs it with Xcode, and
reinstalls it on your iPhone before the signing period expires.

SideRefresh is not an app store, IPA catalog, signing service, or signing bypass.
It runs on the Mac, works with projects you own, and does not require a
jailbreak.

## What SideRefresh does

- Guides you through choosing one Xcode app target and one paired iPhone.
- Rebuilds, signs, validates, and installs the app with Apple tooling.
- Keeps the current app version or advances it automatically at renewal time.
- Records successful installation and signing-expiration evidence.
- Runs a short-lived background Agent, so the app does not stay open.
- Offers a native workspace, CLI, LaunchAgent, and MCP interface.

The Mac must be awake when a renewal is due. Xcode signing, initial device
pairing, Developer Mode, trust, and a reachable device remain required.

## First run

1. In Xcode, sign in with an Apple Account, select your Personal Team, pair the
   iPhone, and run the app on that iPhone once.
2. Open SideRefresh **Settings** and choose **Choose app**. Select one
   `.xcworkspace` or `.xcodeproj`, review the detected app name, Bundle ID,
   version, scheme, and Personal Team, then confirm it in the fixed footer.
3. Choose **Choose iPhone**, select one Xcode-paired iPhone, and confirm it.
4. Keep **No additional address** for normal USB or Xcode network use. The
   optional **Tailscale · Experimental** route requires Tailscale on the Mac
   and iPhone; it checks a remote address but does not replace Xcode pairing.
5. Review the refresh interval and version behavior, then press **Save
   settings** in the fixed footer. When saving is blocked, the footer names the
   next required setup area.
6. Return to **My app**, run **Refresh now** once, and verify the build,
   signing, installation, and recorded expiration.
7. Explicitly enable **Automatic refresh** after the first installation is
   verified.

The Simple workspace, first-run Settings, and app/iPhone selectors include
English and Korean. They follow the preferred macOS app language by default;
use **Settings → Language** to choose **Follow System Settings**, **한국어**, or
**English**. The choice persists across launches. App and device names,
identifiers, and external tool output remain verbatim. See the
[English manual](docs/MANUAL.md) or [Korean manual](docs/MANUAL.ko.md) for the
complete flow.

## Quick start from source

Requirements:

- macOS 13 or later
- Xcode 16.2 or a compatible Swift 6 toolchain

Build and open the native app:

```sh
swift test
Scripts/validate-samples.sh
Scripts/build-app.sh
open dist/SideRefresh.app
```

The build script uses an ad-hoc signature by default. Set
`SIDEREFRESH_SIGNING_IDENTITY` to a local identity when available. Building does
not register the Agent or modify Login Items.

No Python or Go runtime is required by the Swift application.

## How renewal works

```text
User → SideRefresh settings → Agent configuration
                           ↓
launchd → short-lived Agent → renewal engine → iOS helper
                ↘ Tailnet preflight           ↓
                                    xcodebuild + devicectl → iPhone
```

Every renewal uses the source currently on the Mac and performs a real Xcode
build, signing, Bundle ID validation, and CoreDevice installation.

The default smart incremental strategy reuses unchanged build intermediates.
A clean rebuild remains available for troubleshooting.

SideRefresh preserves Xcode's standard build-product layout and resolves the
exact app path from build settings. This keeps CocoaPods and Flutter resource
paths aligned instead of forcing a flattened output directory.

Version behavior is a separate choice: keep the project values or advance the
final numeric component from the higher project/device value.

SideRefresh does not pull Git changes or present cached re-signing as a supported
Personal Team renewal.

See [the iOS renewal helper guide](docs/IOS-RENEWAL.md) for the exact build and
version rules.

The repository's CI workflow uses a GitHub-hosted macOS runner to test a fresh
checkout; it cannot access the project, signing Keychain, or paired iPhone on
the user's Mac. A separate least-privilege workflow is prepared to publish only
the reviewed static website artifact to GitHub Pages.

Unattended renewal runs through the local LaunchAgent on that Mac. A
self-hosted Actions runner could call the CLI on the same prepared Mac, but
SideRefresh does not install or configure one.

## Safety model

SideRefresh requires explicit user action before it:

- discovers Xcode devices or reads installed-app status;
- changes a saved renewal target;
- enables or disables the Login Item;
- switches from dry-run to execute mode; or
- starts an immediate build and installation.

It does not sign in to Apple or Tailscale, store passwords, modify Tailnet
ACLs, install optional device tools, create signing assets, or establish the
initial Xcode/CoreDevice pairing.

Tailscale can provide a network path, but it does not replace Apple signing,
trust, pairing, or the CoreDevice UDID. SideRefresh stores Tailnet identity and
Apple device identity separately.

## Current scope

- One app you own, one Xcode project/workspace, and one paired iPhone per
  configuration.
- A Mac with Xcode and an Apple Account Personal Team is required. Paid Apple
  Developer Program membership is not required for personal-device use.
- Real-device Personal Team build, signing, Bundle ID validation, and
  installation are verified over USB, including a Flutter/CocoaPods workspace.
- SideRefresh does not install third-party IPAs, manage fleets or teams, work
  without Xcode, bypass Apple signing, or make a Personal Team profile
  permanent.
- Tailscale is optional and experimental. It verifies Tailnet peer identity and
  availability; pure-cellular CoreDevice installation remains unverified.
- Source builds are available now. A Developer ID-signed and notarized public
  binary remains a separate release gate.
- This public source repository was created as a sanitized snapshot; private
  development history was not copied into it.
- The reviewed [public product site](https://recrack.github.io/SideRefresh/)
  explains the project in English, Korean, Japanese, and Simplified Chinese.
  It links only to source and release status while the signed, notarized
  download remains a separate release gate.

Read [the full implementation status](docs/STATUS.md) for project discovery,
device evidence, logging, version rules, limitations, and verified behavior.

## Open-source landscape

SideRefresh is an independent MIT-licensed source-build renewal tool. The
projects below solve adjacent build, signing, installation, or renewal
problems; they are not drop-in equivalents.

<details>
<summary>Compare adjacent projects and live GitHub activity</summary>

The badges are served by Shields.io and refresh after its cache expires.

| Project | Adjacent role | Live GitHub activity |
| --- | --- | --- |
| [AltStore](https://github.com/altstoreio/AltStore) | IPA re-signing and desktop-assisted refresh | [![AltStore stars](https://img.shields.io/github/stars/altstoreio/AltStore?style=flat-square&label=stars)](https://github.com/altstoreio/AltStore/stargazers) [![AltStore forks](https://img.shields.io/github/forks/altstoreio/AltStore?style=flat-square&label=forks)](https://github.com/altstoreio/AltStore/forks) |
| [SideStore](https://github.com/SideStore/SideStore) | On-device IPA refresh after initial setup | [![SideStore stars](https://img.shields.io/github/stars/SideStore/SideStore?style=flat-square&label=stars)](https://github.com/SideStore/SideStore/stargazers) [![SideStore forks](https://img.shields.io/github/forks/SideStore/SideStore?style=flat-square&label=forks)](https://github.com/SideStore/SideStore/forks) |
| [fastlane](https://github.com/fastlane/fastlane) | Source build, signing, and distribution automation | [![fastlane stars](https://img.shields.io/github/stars/fastlane/fastlane?style=flat-square&label=stars)](https://github.com/fastlane/fastlane/stargazers) [![fastlane forks](https://img.shields.io/github/forks/fastlane/fastlane?style=flat-square&label=forks)](https://github.com/fastlane/fastlane/forks) |
| [XcodeBuildMCP](https://github.com/getsentry/XcodeBuildMCP) | Xcode build and device operations through CLI and MCP | [![XcodeBuildMCP stars](https://img.shields.io/github/stars/getsentry/XcodeBuildMCP?style=flat-square&label=stars)](https://github.com/getsentry/XcodeBuildMCP/stargazers) [![XcodeBuildMCP forks](https://img.shields.io/github/forks/getsentry/XcodeBuildMCP?style=flat-square&label=forks)](https://github.com/getsentry/XcodeBuildMCP/forks) |
| [RebuildMe](https://github.com/AryanRogye/RebuildMe) | Source rebuild on a Mac and `devicectl` installation over SSH | [![RebuildMe stars](https://img.shields.io/github/stars/AryanRogye/RebuildMe?style=flat-square&label=stars)](https://github.com/AryanRogye/RebuildMe/stargazers) [![RebuildMe forks](https://img.shields.io/github/forks/AryanRogye/RebuildMe?style=flat-square&label=forks)](https://github.com/AryanRogye/RebuildMe/forks) |
| [ReProvision Reborn](https://github.com/sohsatoh/ReProvision-Reborn) | Automatic re-signing on jailbroken iOS devices | [![ReProvision Reborn stars](https://img.shields.io/github/stars/sohsatoh/ReProvision-Reborn?style=flat-square&label=stars)](https://github.com/sohsatoh/ReProvision-Reborn/stargazers) [![ReProvision Reborn forks](https://img.shields.io/github/forks/sohsatoh/ReProvision-Reborn?style=flat-square&label=forks)](https://github.com/sohsatoh/ReProvision-Reborn/forks) |
| [Feather](https://github.com/claration/Feather) | On-device IPA signing and installation | [![Feather stars](https://img.shields.io/github/stars/claration/Feather?style=flat-square&label=stars)](https://github.com/claration/Feather/stargazers) [![Feather forks](https://img.shields.io/github/forks/claration/Feather?style=flat-square&label=forks)](https://github.com/claration/Feather/forks) |
| [ios-deploy](https://github.com/ios-control/ios-deploy) | Signed app installation and debugging before iOS 17 | [![ios-deploy stars](https://img.shields.io/github/stars/ios-control/ios-deploy?style=flat-square&label=stars)](https://github.com/ios-control/ios-deploy/stargazers) [![ios-deploy forks](https://img.shields.io/github/forks/ios-control/ios-deploy?style=flat-square&label=forks)](https://github.com/ios-control/ios-deploy/forks) |
| [pymobiledevice3](https://github.com/doronz88/pymobiledevice3) | Cross-platform device protocol and installation primitives | [![pymobiledevice3 stars](https://img.shields.io/github/stars/doronz88/pymobiledevice3?style=flat-square&label=stars)](https://github.com/doronz88/pymobiledevice3/stargazers) [![pymobiledevice3 forks](https://img.shields.io/github/forks/doronz88/pymobiledevice3?style=flat-square&label=forks)](https://github.com/doronz88/pymobiledevice3/forks) |
| [ideviceinstaller](https://github.com/libimobiledevice/ideviceinstaller) | App installation and upgrade primitives | [![ideviceinstaller stars](https://img.shields.io/github/stars/libimobiledevice/ideviceinstaller?style=flat-square&label=stars)](https://github.com/libimobiledevice/ideviceinstaller/stargazers) [![ideviceinstaller forks](https://img.shields.io/github/forks/libimobiledevice/ideviceinstaller?style=flat-square&label=forks)](https://github.com/libimobiledevice/ideviceinstaller/forks) |
| [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice) | Device services and optional provisioning-profile inspection | [![libimobiledevice stars](https://img.shields.io/github/stars/libimobiledevice/libimobiledevice?style=flat-square&label=stars)](https://github.com/libimobiledevice/libimobiledevice/stargazers) [![libimobiledevice forks](https://img.shields.io/github/forks/libimobiledevice/libimobiledevice?style=flat-square&label=forks)](https://github.com/libimobiledevice/libimobiledevice/forks) |
| [LiveContainer](https://github.com/LiveContainer/LiveContainer) | Running guest IPAs inside a host iOS app | [![LiveContainer stars](https://img.shields.io/github/stars/LiveContainer/LiveContainer?style=flat-square&label=stars)](https://github.com/LiveContainer/LiveContainer/stargazers) [![LiveContainer forks](https://img.shields.io/github/forks/LiveContainer/LiveContainer?style=flat-square&label=forks)](https://github.com/LiveContainer/LiveContainer/forks) |
| [TrollStore](https://github.com/opa334/TrollStore) | Permanent IPA installation on limited vulnerable iOS versions | [![TrollStore stars](https://img.shields.io/github/stars/opa334/TrollStore?style=flat-square&label=stars)](https://github.com/opa334/TrollStore/stargazers) [![TrollStore forks](https://img.shields.io/github/forks/opa334/TrollStore?style=flat-square&label=forks)](https://github.com/opa334/TrollStore/forks) |

</details>

GPL or AGPL code from adjacent projects must not be copied into or bundled with
the MIT core without a license review.

See the
[open-source viability research](docs/research/open-source-viability-and-landscape.md)
for the full comparison and publication plan.

## Documentation

| Guide | Contents |
| --- | --- |
| [User manual — English](docs/MANUAL.md) · [한국어](docs/MANUAL.ko.md) | First setup, connection choices, saving, and renewal |
| [Personal Team — English](docs/PERSONAL-TEAM-SETUP.md) · [한국어](docs/PERSONAL-TEAM-SETUP.ko.md) | Signing preparation and troubleshooting |
| [Product Hunt playbook](docs/product-hunt/README.md) · [Launch assets](docs/product-hunt/assets/README.md) · [English copy](docs/PRODUCT-HUNT.md) · [한국어](docs/PRODUCT-HUNT.ko.md) | Registration, generated media, bilingual copy, demo package, promotion, and launch gates |
| [Website source — English](docs/index.html) · [한국어](docs/ko/index.html) · [日本語](docs/ja/index.html) · [简体中文](docs/zh-cn/index.html) · [Public-readiness audit](docs/product-hunt/public-readiness-audit.md) | Four-language product explanation and the source, license, binary, and launch blockers |
| [Implementation status](docs/STATUS.md) | Current behavior, evidence, and limitations |
| [iOS renewal helper](docs/IOS-RENEWAL.md) | Dry run, build strategy, and version policy |
| [CLI, LaunchAgent, and MCP](docs/HEADLESS.md) | Headless install and automation |
| [Distribution](docs/DISTRIBUTION.md) | Source builds and Developer ID release path |
| [Examples](Examples/README.md) | Sample app, dry run, and device template |
| [Architecture diagram](docs/side-refresh-architecture.html) | Interactive system flow |
| [Architecture source](docs/side-refresh.architecture.json) | Validated diagram data |
| [Device data inventory](docs/DEVICE-DATA-INVENTORY.ko.md) | Available and unavailable iPhone fields |

## Development

Git does not activate repository hooks after clone. Install them once per
checkout:

```sh
Scripts/install-git-hooks.sh
```

Pre-commit checks staged changes and runs Swift tests only for Swift package
changes. Pre-push runs the full local validation. Pull-request CI repeats the
independent checks on a GitHub-hosted Mac without renewing an app or running
again after merge.

Run the full Swift test suite and sample validation manually:

```sh
swift test
Scripts/validate-samples.sh
Scripts/validate-headless.sh
```

The iOS sample is also built without signing by the validation workflow.

Contributions are welcome under [CONTRIBUTING.md](CONTRIBUTING.md). Please use
the private process in [SECURITY.md](SECURITY.md) for sensitive reports.

## License

MIT. See [LICENSE](LICENSE).
