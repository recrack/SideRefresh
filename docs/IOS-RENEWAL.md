# SideRefresh iOS renewal helper

`SideRefreshIOSRenewal` is the build, signing, validation, and CoreDevice
installation helper used by the macOS app, CLI, LaunchAgent, and MCP server.

## Inputs

The helper accepts:

- an `.xcodeproj` or `.xcworkspace`;
- a scheme and build configuration;
- a Personal Team ID;
- the expected Bundle ID;
- a product name;
- a CoreDevice UDID;
- a Derived Data path;
- a build strategy; and
- a version policy.

## Safe dry run

Inspect a plan without changing the Mac or iPhone:

```sh
swift run SideRefreshIOSRenewal \
  --dry-run \
  --container /absolute/path/App.xcodeproj \
  --scheme App \
  --team YOUR_TEAM_ID \
  --bundle-id your.unique.bundle.identifier \
  --product App \
  --device YOUR_DEVICE_UDID \
  --derived-data /absolute/path/DerivedData
```

Dry-run mode asks Xcode for the resolved app-product path, then prints the
planned `xcodebuild` and `devicectl` commands. It uses a generic iOS destination
for this read-only lookup and does not contact the selected iPhone. It does not
build, sign, install, or update a renewal receipt.

After the initial Xcode and device path is proven, replace `--dry-run` with
`--execute` to enable signing, building, and installation. This is an explicit
configuration change.

## Execute flow

Execute mode:

1. optionally reads the installed version for automatic versioning;
2. runs `xcodebuild -showBuildSettings` with the same team, renewal, and
   version overrides as the build;
3. selects the application target matching the configured Bundle ID;
4. resolves its app from `TARGET_BUILD_DIR` and `FULL_PRODUCT_NAME`;
5. runs the selected Xcode build strategy;
6. verifies the resulting app's Bundle ID;
7. reads the embedded provisioning profile expiration;
8. installs the resolved app through CoreDevice; and
9. returns the evidence needed for a successful-renewal receipt.

A Bundle ID mismatch stops the run before installation.

## Build strategy

Every renewal rebuilds, signs, and installs the source currently on the Mac.
SideRefresh does not pull Git changes.

Supported strategies:

- `incremental` keeps stable Derived Data so Xcode can reuse unchanged
  intermediate results.
- `clean-rebuild` runs `xcodebuild clean build` for troubleshooting.

SideRefresh does not override `CONFIGURATION_BUILD_DIR`. Xcode, CocoaPods, and
Flutter therefore keep their normal shared Products layout. Before an
incremental build, SideRefresh removes only the resolved `.app` when its
symlink-resolved path is inside the selected Derived Data directory.

SideRefresh does not support a cached no-build re-sign as a Personal Team
renewal path.

## Build-log troubleshooting

Release-build notes such as `SWIFT_OPTIMIZATION_LEVEL=-O, expected -Onone`,
`Disabling previews`, and an always-running script phase are not failures by
themselves. Use `BUILD SUCCEEDED` or `BUILD FAILED` and the first preceding
`error:` as the result boundary.

For Flutter or CocoaPods projects, select the `.xcworkspace`. A
`[CP] Copy Pods Resources` missing-bundle error can occur when an external tool
flattens `CONFIGURATION_BUILD_DIR` while Pods still use Xcode's configuration
Products directory. Current SideRefresh preserves Xcode's resolved output
layout and installs the exact Bundle-ID-matched app returned by build settings.

## Version policy

Version policy is separate from build strategy.

- `keep` leaves `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` unchanged.
- `automatic` reads the version installed on the selected iPhone immediately
  before renewal and compares it with the selected project's version.

Automatic mode advances the final numeric component of each higher value:

| Current shape | Next value |
| --- | --- |
| `1` | `2` |
| `1.0` | `1.1` |
| `1.2.9` | `1.2.10` |

If the app is not installed, the project version is the starting point.
Existing saved configurations default to `keep`.

## Apple prerequisites

The helper does not create the initial Apple development path. Before execute
mode can succeed, the user must provide:

- Xcode signed in with an Apple ID;
- a selected and prepared Personal Team;
- an Apple Development identity and provisioning assets;
- Developer Mode and accepted trust prompts on the iPhone;
- initial Xcode/CoreDevice pairing; and
- an awake Mac with the selected iPhone reachable.

SideRefresh never stores Apple credentials or creates, revokes, or changes
signing assets.

## Sample validation

Build the native sample for a Simulator without signing:

```sh
xcodebuild \
  -project Examples/SideRefreshSampleApp/SideRefreshSample.xcodeproj \
  -scheme SideRefreshSample \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/side-refresh-sample-simulator \
  CODE_SIGNING_ALLOWED=NO \
  build
```

See [Examples/README.md](../Examples/README.md) for the dry-run command,
real-device template, and Tailnet boundary.
