# Changelog

All notable changes will be documented here.

The format is based on Keep a Changelog. SideRefresh does not yet make
compatibility guarantees under semantic versioning.

## Unreleased

## 0.2.0-beta.2 - 2026-08-08

### Changed

- Adopted Apache License 2.0 for source code and prose documentation beginning
  with this release, including explicit contributor patent terms and project
  attribution in `NOTICE`.
- Separated the SideRefresh name and visual identity into a brand policy for
  modified and derived distributions.
- Added `LICENSE`, `NOTICE`, and `BRAND_POLICY.md` to app and Headless build
  outputs.
- Updated repository, website, contribution, Product Hunt, and release
  documentation to state the Apache-2.0 boundary consistently.
- Preserved the original MIT terms and historical records for versions through
  `v0.2.0-beta.1`.

### Known limitations

- This remains a source-only prerelease without a downloadable Developer
  ID-signed and notarized Mac app.
- No functional renewal behavior or verified device compatibility changed in
  this release.

## 0.2.0-beta.1 - 2026-08-06

### Added

- Added explicit Desktop, Documents, Downloads, and custom-folder access
  status to the project picker.
- Added repository-managed pre-commit and pre-push validation hooks with a
  one-time installer.
- Added a multilingual GitHub Pages product site in English, Korean, Japanese,
  and Simplified Chinese.

### Changed

- Standardized the product and search-oriented description as
  **SideRefresh — Automatic iOS App Refresh**.
- Standardized Swift modules, app and helper executables, CLI/MCP commands,
  sample targets, resources, and documentation on the SideRefresh name.
- Finalized the pre-release app identifier as `io.github.siderefresh.macos`
  and the LaunchAgent identifier as `io.github.siderefresh.renewal`.
- Standardized Application Support, UserDefaults, cache, build-setting, and
  progress-protocol keys on SideRefresh.
- Developer ID builds use `SIDEREFRESH_SIGNING_IDENTITY`.
- Improved project discovery with batched results, cached candidates, a
  persistent selection action, and explicit folder-access guidance.
- Preserved Xcode's resolved Products layout and exact app path for
  Flutter/CocoaPods resource builds.
- Added Headless/MCP checks to GitHub Actions validation for pull requests and
  pushes to `master`.
- Made the Simple workspace the default launch experience with consistent
  in-window navigation for My app, Settings, Help, and Diagnostics.
- Published a privacy-reviewed public source repository with contribution,
  support, security, and release documentation.

### Known limitations

- This is a source-only prerelease. It does not include a downloadable,
  Developer ID-signed and notarized Mac app.
- One renewal target is supported per configuration.
- Initial Xcode/CoreDevice pairing and the first Xcode installation remain
  manual.
- Pure-cellular CoreDevice installation over Tailscale is not a verified
  support claim.

## 0.1.0 - 2026-07-28

### Added

- Native SwiftUI menu-bar app and settings.
- Scheduled renewal Agent using `SMAppService`.
- Xcode project/workspace discovery with Spotlight and bounded scanning.
- Dry-run-first Xcode build and CoreDevice installation helper.
- Bundle ID verification before installation.
- Automatic, Tailscale, and custom-address connection guidance.
- Native iOS sample app and non-mutating validation script.
- SideRefresh brand mark and macOS application icon.
- App-aware version policies that either keep the current version or advance
  from the newer project and installed-app versions.
- Headless CLI, LaunchAgent installation, and an MCP server for status,
  configuration, dry-run, and explicitly confirmed renewal commands.
- Sample-app renewal evidence that distinguishes an update install from a
  fresh installation.

### Changed

- Product, package, executable, storage, bundle, and Agent identities now use
  SideRefresh exclusively.
- Automatic project discovery now shows only containers with a detectable iOS
  application target. Manual project/workspace selection remains available
  for uncommon generated layouts.
- Project results show iOS application target names and recommend a Workspace
  only when it actually references the matching Project.
- Mixed-platform projects identify iOS targets from target-specific build
  configurations, and nested Workspace groups resolve project references
  relative to their parent groups.
- The settings and project-picker windows open at a roomier Mac-friendly size,
  and the settings window restores the user's last resized frame.
- Development builds start with fresh settings and background registration.
- Developer ID builds use `SIDEREFRESH_SIGNING_IDENTITY`. A real identity enables
  hardened runtime and secure timestamps; an unset value remains an ad-hoc
  local build.
- The menu-bar popover is prepared against its real status item, reducing
  click-to-visible latency without removing menu actions.
- Release packaging excludes local Xcode sample build products.

### Known limitations

- One renewal target per configuration.
- Initial Xcode/CoreDevice pairing and unknown-IP registration remain manual.
- Cellular-only CoreDevice installation over Tailscale is not yet verified.
- Binary releases are not Developer ID signed or notarized yet.
