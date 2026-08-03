# SideRefresh distribution

## Current channel: source build

SideRefresh is currently distributed as source under the MIT License.

```sh
swift test
Scripts/validate-samples.sh
Scripts/build-app.sh
open dist/SideRefresh.app
```

The build script creates `dist/SideRefresh.app`, signs it ad hoc, and does not
launch the app, register its background Agent, or change Login Items. An ad-hoc
signature is for local development; it does not make a downloaded binary
trusted by Gatekeeper.

The current identifiers are:

- app bundle: `io.github.siderefresh.macos`;
- LaunchAgent: `io.github.siderefresh.renewal`;
- Swift package: `SideRefresh`;
- CLI: `side-refresh`.

All product, storage, executable, sample, and reverse-DNS identifiers use the
SideRefresh name.

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
- [ ] Final bundle and Agent identifiers match this document.
- [ ] App, embedded executables, and archive pass signature verification.
- [ ] Apple notarization succeeds and the ticket is stapled.
- [ ] Gatekeeper assessment succeeds on the stapled app.
- [ ] Fresh-account launch, Settings, dry run, and Agent approval are tested.
- [ ] Real-device execute testing documents the exact network path used.
- [ ] Release archive SHA-256 is published.
