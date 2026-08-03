# SideRefresh implementation status

This document records the current behavior, verified scope, and known
limitations of SideRefresh. For the user-facing setup flow, see the
[English manual](MANUAL.md) or [Korean manual](MANUAL.ko.md).

## Renewal engine

The macOS scheduling layer and generic iOS build/install helper are
implemented.

The scheduler:

- stores only successful renewal state;
- prevents overlapping runs;
- preserves the latest 64 KiB of each command-output stream;
- retries after failures;
- gives a renewal command a 30-minute deadline; and
- terminates the command's process group after a timeout or runner failure
  before releasing the lock.

Every Personal Team renewal performs an Xcode build, signing, and installation.
SideRefresh does not pull Git changes and does not support a cached no-build
re-sign path.

The helper preserves Xcode's standard Products layout instead of overriding
`CONFIGURATION_BUILD_DIR`. It resolves `TARGET_BUILD_DIR` and
`FULL_PRODUCT_NAME` with the same build-setting overrides used by the real
build, then validates and installs that exact Bundle-ID-matched app.

Build strategy and version policy are configured independently. Their exact
behavior is documented in the
[iOS renewal helper guide](IOS-RENEWAL.md).

## Verified scope

A real-device sample build, Personal Team signing, and installation have been
verified over USB.

A Release smart-incremental build, signing, Bundle ID validation, and update
installation have also been verified with a real Flutter/CocoaPods workspace
on a paired iPhone.

Pure-cellular installation through a Tailscale direct-IP connection remains
unverified. SideRefresh does not claim that Apple CoreDevice works over a
cellular-only Tailnet path.

The helper does not create the initial Xcode/CoreDevice connection. Signing in
to Xcode, enabling Developer Mode, accepting trust prompts, and initial pairing
remain user-controlled Apple setup steps.

The current configuration supports one iOS app target. Supporting multiple
apps requires separate target profiles and renewal state. SideRefresh does not
scan and install every project on the Mac.

## Workspace

The Simple workspace is the default launch experience. Its **My app** screen
presents the primary relationship:

```text
Mac app → build, sign, install → destination iPhone
```

The fixed left sidebar keeps **My app** selected at launch and exposes
Settings, Help, and Diagnostics without a collapsible toolbar control or an
extra window. Selecting a sidebar item keeps the sidebar in place and replaces
the primary page in the launch window. The main header shows the current app
identity on the left and compact historical Last verified evidence on the
right. The scrollable body then orders renewal condition, at most one next
action, the selected app-to-iPhone relationship, timing, and the current or
most recent result. Destination buttons are not duplicated in the bottom
footer.

Settings is a page in the launch window. Choosing an app or iPhone replaces
that page's content and returns to the overview after confirmation. A fixed
footer shows one of three states: incomplete with the next required setup
area, unsaved with an enabled save action, or saved with no pending action.

The iPhone connection section always shows Xcode/CoreDevice readiness. Optional
Tailscale discovery is labelled experimental and remains separate from Xcode
pairing: Tailscale online status is not presented as proof that Xcode can
install. Selecting Tailscale blocks saving until the Mac executable and one
Tailnet iPhone are available.

The renewal target includes:

- Xcode project or workspace;
- scheme and product;
- expected Bundle ID;
- Personal Team; and
- CoreDevice UDID.

**Load bundled sample configuration** fills the embedded helper and native
sample project in `--dry-run` mode.

The Simple and Settings window frames are restored between openings. Command-S
uses the same confirmation as the fixed Save button.

The app bundle contains English and Korean localizations for the Simple
workspace, first-run Settings, app/iPhone selectors, and usage descriptions.
Settings exposes a persisted app-language choice: follow the macOS app
language, Korean, or English. Changing it updates open Simple surfaces and
localized window titles without changing the global `AppleLanguages` default.
User-provided app names, iPhone names, Bundle IDs, versions, addresses,
identifiers, Diagnostics, and external tool output remain verbatim. Advanced
legacy surfaces are not part of this localization claim.

## Project discovery

The project picker uses Spotlight first, then complements its results with a
cancellable, utility-priority scan under the user's home directory.

Filesystem results arrive in batches of 20. The picker caches valid previous
results, skips high-cost or generated trees such as `Library`, `DerivedData`,
`.git`, `Pods`, and `node_modules`, and limits automatic results to 200.

The picker exposes access state for the home directory, Desktop, Documents,
Downloads, and user-added folders. It asks the user to confirm a protected
location and explains that discovery reads Xcode target metadata and app icons,
not source contents.

Automatic results must contain an iOS application target. This filters macOS
apps, frameworks, package workspaces, and empty containers. Workspaces are
accepted when they reference an iOS application project.

Manual selection remains available for generated or uncommon setups that the
static check cannot recognize. An unparseable manually selected target is
labelled unverified rather than using the container filename as an app name.

Each result shows an app name derived from `CFBundleDisplayName`,
`CFBundleName`, or `PRODUCT_NAME`, the Xcode application target, and its
relative container path. The detail view exposes the full path.

A workspace is recommended only when its data references the matching app
project. Discovery never changes the renewal target until the user selects a
candidate and confirms **Use**.

When a container has exactly one iOS application target, SideRefresh reads its
Release `PRODUCT_NAME`, `PRODUCT_BUNDLE_IDENTIFIER`, and `DEVELOPMENT_TEAM`.
It fills the scheme only when exactly one matching scheme exists.

Workspace-level schemes are included. Missing or ambiguous values still
require confirmation in Xcode. SideRefresh never silently selects the first of
multiple application targets.

## Target validation

The project path and scheme determine what to build. The expected Bundle ID
verifies what was built. The CoreDevice UDID determines which iPhone receives
it.

After the build, SideRefresh reads the app's `Info.plist` and stops before
installation when its Bundle ID differs from the configured value.

Choosing a container does not infer a scheme or product solely from the
filename.

## Device discovery and connections

SideRefresh reads Xcode's known-device list only after the user presses the
discovery button. A single paired iPhone is selected automatically.

When several iPhones exist, the picker shows each name, model, iOS version, and
a short UDID suffix. Manual UDID entry remains available.

Three connection routes are represented:

- an existing automatic/CoreDevice connection;
- explicit Tailscale discovery; or
- a custom IP or DNS address for Xcode's connection UI.

Changing network addresses are not treated as installation identity.
CoreDevice UDID selects the iPhone.

When a Tailnet iPhone is selected, SideRefresh stores its stable Node ID and DNS
name. A due Agent run reads `tailscale status --json` again, resolves the peer,
and refuses to record success when that peer is offline.

If the saved peer disappears, the UI requires an explicit replacement instead
of selecting the first result. This preflight does not register a new address
with Xcode.

Tailscale does not expose the Apple UDID. SideRefresh keeps the CoreDevice UDID
and Tailnet Node ID as separate, explicitly selected identities.

The optional `side-refresh tailnet discover` command can parse a saved status
file. With an explicit absolute Tailscale executable path, it runs only
`tailscale status --json`.

It returns iOS peers and their preferred Tailnet addresses without changing
Tailscale.

## Manual actions and logs

The Simple workspace exposes **Refresh now**. It bypasses the schedule after
confirmation, performs the real build and installation, and records the exact
embedded profile `ExpirationDate`.

During a real run, the Simple activity card shows one current progress summary.
After completion it shows the latest verified or failed result. Raw live
`xcodebuild` and CoreDevice output stays in Diagnostics rather than filling the
workspace.

The menu bar and workspace open Diagnostics in a resizable native log window
with:

- macOS Find;
- text selection and full-log copy;
- line wrapping;
- user-controlled live following;
- jump to latest; and
- `.log` export.

## Installed app and provisioning evidence

`devicectl device info apps` confirms developer-app name, Bundle ID, version,
build number, removability, and device bundle path. It does not expose
provisioning expiration.

When the open-source `ideviceprovision` tool is available, SideRefresh can copy
installed provisioning profiles read-only and match them by application
identifier.

It tries the paired USB or local service first. If that command fails, it
retries the same read-only operation once with `--network`. Inspection never
installs, removes, or changes a profile.

For an exact match, SideRefresh can expose:

- Apple Development certificate name and team;
- profile UUID and App ID;
- issue and expiration dates;
- platform;
- registered-device inclusion; and
- entitlement keys.

A receipt UUID proves only that the same profile remains on the iPhone. It
cannot prove that an app reinstalled outside SideRefresh still embeds that
profile. A Bundle ID-only match is labelled as a candidate.

When the optional backend is unavailable or the match is ambiguous, SideRefresh
keeps expiration tied to its own successful-install receipt. It does not
present an estimate as device truth.

## Personal Team discovery

The bundled sample does not treat `REPLACE_WITH_TEAM_ID` or other placeholders
as executable settings.

SideRefresh checks local provisioning profiles away from the UI thread. It
autofills a Personal Team identifier only when the local evidence is
unambiguous.

An expired Personal Team profile can recover its stable Team ID but is shown as
requiring Xcode preparation.

**Find Team on this Mac** can read Apple Development certificate OUs as
fallback candidates. Certificate-only evidence is not proof of a Personal Team
and always requires confirmation.

When several teams exist, the user must choose. Team discovery and setup
guidance stay visible in the app-target card rather than being hidden under
advanced build fields.

The user must review and save a repaired target before installation. SideRefresh
never collects Apple Account credentials or creates, revokes, or changes
signing assets.

## Background registration

Saving writes configuration to the user's SideRefresh Application Support
directory.

Enabling background renewal requires separate confirmation and uses
`SMAppService`. Changing an enabled target also requires confirmation because
the new configuration can run at the next schedule.

The confirmation warns that `SMAppService.register()` may start the configured
Agent immediately. Registration with the current ad-hoc local signature still
needs a real-machine feasibility test.

The app bundle and embedded Agent are signed separately. Building the app does
not register the Agent or change Login Items.

## Development validation

Repository-managed Git hooks are opt-in because clone does not activate them.
`Scripts/install-git-hooks.sh` sets the checkout's local `core.hooksPath`.

Pre-commit checks the staged diff and runs Swift tests only for Swift package
changes. Pre-push runs Swift tests, iOS sample validation, and Headless/MCP
validation.

Pull-request CI repeats those checks on GitHub's `macos-15` hosted runner. It is
validation only: it does not use signing credentials, contact an iPhone, or
perform renewal. The workflow does not run again after merge.

Actual scheduled renewal remains a local LaunchAgent responsibility. A
self-hosted runner on the prepared Mac could invoke the CLI, but no such
workflow or runner registration is included.

## Swift migration

The original Python prototype remains under `ios_tailnet_preflight/` as a
behavior reference while Swift parity is verified. It will be removed only
after feature parity is confirmed.

## Design research

- [macOS SwiftUI project discovery](research/swiftui-macos-project-discovery-ui.md)
  records the workspace and project-picker rationale.
- [iPhone renewal connection alternatives](research/iphone-renewal-connection-alternatives.md)
  compares the Apple-supported USB/LAN boundary with provider-neutral and
  remote alternatives.
