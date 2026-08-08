# SideRefresh distribution

## Current channel: source prerelease

SideRefresh `v0.2.0-beta.2` is distributed as a source-only prerelease under
Apache License 2.0. GitHub's generated source archives contain the tagged source;
they are not signed Mac application downloads.

Versions through `v0.2.0-beta.1` remain available under their original MIT
terms. SideRefresh names and visual assets in later versions follow the
[brand policy](../BRAND_POLICY.md).

```sh
swift test
Scripts/validate-samples.sh
Scripts/build-app.sh
open dist/SideRefresh.app
```

The build script creates `dist/SideRefresh.app`, signs it ad hoc, and does not
launch the app, register its background Agent, or change Login Items. An ad-hoc
signature is for local development; it does not make a downloaded binary
trusted by Gatekeeper. The app resources include `LICENSE`, `NOTICE`, and
`BRAND_POLICY.md`; the Headless package carries the same files at its root.

The current identifiers are:

- app bundle: `io.github.siderefresh.macos`;
- LaunchAgent: `io.github.siderefresh.renewal`;
- Swift package: `SideRefresh`;
- CLI: `side-refresh`.

All product, storage, executable, sample, and reverse-DNS identifiers use the
SideRefresh name.

## Remove a source build

1. Disable **Automatic refresh** in SideRefresh before removing the app. For a
   Headless installation, run `side-refresh schedule disable --confirm` first.
2. Quit SideRefresh and remove the locally built `dist/SideRefresh.app`.
3. To remove all retained configuration and evidence, delete the `SideRefresh`
   folders from `~/Library/Application Support` and `~/Library/Caches`, then
   remove the `io.github.siderefresh.macos` defaults domain.
4. A Headless installation may also have
   `~/Library/LaunchAgents/io.github.siderefresh.renewal.plist`; remove it only
   after the schedule-disable command succeeds.

Removing configuration is optional and cannot be undone. It deletes the saved
renewal target and Last verified evidence, but it does not delete the user's
Xcode project or the app already installed on the iPhone.

## Pre-release identity policy

No public binary has been distributed. Development builds therefore start
with a fresh SideRefresh configuration, receipt store, UserDefaults domain,
and background Agent registration. There is no pre-release identifier
migration layer.

## Why the Mac App Store is not the target

The core workflow launches `xcodebuild`, `devicectl`, and optionally the
Tailscale executable; discovers user-owned projects; and runs their configured
build scripts. Those operations do not fit the Mac App Store sandbox model.
The planned binary channel is therefore Developer ID signing and Apple
notarization outside the Mac App Store.

## Future Developer ID release

After joining the Apple Developer Program:

1. Create or install a `Developer ID Application` certificate.
2. Keep the documented bundle and LaunchAgent identifiers stable.
3. Build with the real signing identity:

   ```sh
   SIDEREFRESH_SIGNING_IDENTITY='Developer ID Application: Example (TEAMID)' \
     Scripts/build-app.sh
   ```

   For a real identity, the script enables hardened runtime and a secure
   timestamp. It signs the embedded Agent and iOS helper before the outer app.

4. Inspect and verify the result:

   ```sh
   codesign --display --verbose=4 dist/SideRefresh.app
   codesign --verify --deep --strict --verbose=2 dist/SideRefresh.app
   ```

5. Store notarization credentials in Keychain under a local profile. Never
   commit Apple credentials or API keys.
6. Submit a ZIP, wait for the result, and staple the ticket:

   ```sh
   ditto -c -k --sequesterRsrc --keepParent \
     dist/SideRefresh.app dist/SideRefresh.zip
   xcrun notarytool submit dist/SideRefresh.zip \
     --keychain-profile SideRefresh-notary \
     --wait
   xcrun stapler staple dist/SideRefresh.app
   xcrun stapler validate dist/SideRefresh.app
   spctl --assess --type execute --verbose=4 dist/SideRefresh.app
   ```

7. Recreate the ZIP after stapling and publish its checksum with the release.
8. Test the downloaded archive on a clean macOS account before publishing.

Do not claim that a build is notarized based only on successful `codesign`
output. Notarization and stapling are separate checks.

## Release checklist

- [ ] Swift tests, sample validation, and Headless/MCP validation pass.
- [ ] Version and build numbers are updated.
- [ ] Changelog is updated.
- [ ] `LICENSE`, `NOTICE`, brand policy, and third-party notices are packaged.
- [ ] Final bundle and Agent identifiers match this document.
- [ ] App, embedded executables, and archive pass signature verification.
- [ ] Apple notarization succeeds and the ticket is stapled.
- [ ] Gatekeeper assessment succeeds on the stapled app.
- [ ] Fresh-account launch, Settings, dry run, and Agent approval are tested.
- [ ] Real-device execute testing documents the exact network path used.
- [ ] Release archive SHA-256 is published.
