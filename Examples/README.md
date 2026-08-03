# SideRefresh samples

This directory contains a complete, intentionally small renewal example:

- `SideRefreshSampleApp/`: a native SwiftUI iOS app and shared Xcode scheme;
- `Configurations/agent.dry-run.json`: a non-mutating configuration template;
- `Configurations/agent.device.json`: an explicit real-device template.
- `Tailnet/tailscale-status.sample.json`: offline Tailnet discovery input.

The checked-in templates contain placeholders. SideRefresh's **Load bundled
sample configuration** button creates the same dry-run configuration with
valid absolute paths from the built app bundle.

## 1. Build the sample without signing or launching anything

From the repository root:

```sh
xcodebuild \
  -project Examples/SideRefreshSampleApp/SideRefreshSample.xcodeproj \
  -scheme SideRefreshSample \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/side-refresh-sample-simulator \
  CODE_SIGNING_ALLOWED=NO \
  build
```

This compiles the app for the Simulator but does not boot a Simulator, contact
Apple, change signing settings, or install an app.

The repository provides the same build plus dry-run verification as:

```sh
Scripts/validate-samples.sh
```

## 2. Inspect the renewal plan

Build the Swift helper and ask it for a dry run:

```sh
swift build --product SideRefreshIOSRenewal

.build/debug/SideRefreshIOSRenewal \
  --dry-run \
  --version-policy keep \
  --source-marketing-version 1.0 \
  --source-build-version 1 \
  --container /ABSOLUTE/PATH/TO/SideRefreshSample.xcodeproj \
  --scheme SideRefreshSample \
  --team REPLACE_WITH_TEAM_ID \
  --bundle-id io.github.siderefresh.sample.replace-me \
  --product SideRefreshSample \
  --device REPLACE_WITH_DEVICE_UDID \
  --derived-data /ABSOLUTE/PATH/TO/SideRefreshDerivedData
```

Dry-run is the default and prints the exact `xcodebuild` and `devicectl`
commands as JSON. It reports `"system_changes_performed": false`.

`--version-policy keep` preserves the sample's `1.0 (1)`. Selecting
`automatic` in the SideRefresh app shows `1.0 (1) → 1.1 (2)` before the first
renewal. Later renewals read the version currently installed on the iPhone, so
they continue to `1.2 (3)`, `1.3 (4)`, and so on instead of repeatedly building
the same `1.1 (2)`. The sample already displays the real bundle version, so the
changed values are visible inside the installed app.

The helper accepts either an `.xcodeproj` or `.xcworkspace` path. This makes
the same sample applicable to native Swift, Flutter, and generated
Expo/React Native iOS workspaces. `--bundle-id` is an expected value used to
verify the output; configure that identifier in the selected Xcode target
before execute mode.

## 3. Load the bundled sample in the menu-bar app

```sh
Scripts/build-app.sh
```

Open `dist/SideRefresh.app`, choose **Settings**, then choose
**Load bundled sample configuration**. The **갱신 대상 앱** card shows
the sample project, scheme, product, expected Bundle ID, Personal Team, and
iPhone UDID as separate fields. The populated target uses **테스트 · 변경 없음**
(`--dry-run`); saving or running it cannot build or install the iOS app.

SideRefresh never registers its background Agent merely by loading or saving
the sample. **Enable background renewal** remains a separate confirmation.

## 4. Discover the iPhone's Tailnet address

First verify parsing without invoking Tailscale:

```sh
swift run side-refresh tailnet discover \
  --status-file \
  /ABSOLUTE/PATH/TO/Examples/Tailnet/tailscale-status.sample.json
```

To read your live Tailnet, explicitly pass the absolute Tailscale CLI path:

```sh
test -x /Applications/Tailscale.app/Contents/MacOS/Tailscale

swift run side-refresh tailnet discover \
  --tailscale /Applications/Tailscale.app/Contents/MacOS/Tailscale
```

The live form runs only `tailscale status --json`. It does not log in, enable
the VPN, change preferences, or modify ACLs. Its JSON response contains only
iOS peers under `devices`, prefers an IPv4 address when available, retains all
Tailnet addresses, and reports `"system_changes_performed": false`.
For the App Store macOS client, SideRefresh sets `TAILSCALE_BE_CLI=1` only in
that child process so the bundled executable emits CLI JSON.

Some localized App Store installations use this executable instead:

```text
/Applications/Tailscale.localized/Tailscale.app/Contents/MacOS/Tailscale
```

If both paths exist, use the one belonging to the currently connected
Tailscale instance. Passing a disconnected older copy cannot discover the
live Tailnet and does not cause SideRefresh to connect it.

If more than one iOS device is listed, select the online iPhone by
`host_name`/`dns_name`. Copy `preferred_ip_address` into Xcode's
**Connect via IP Address** UI. The Tailnet IP is for the initial connection;
the renewal helper separately needs the device UDID reported by CoreDevice.

The macOS app exposes the same operation under **설치할 iPhone → Tailscale**.
Live discovery occurs only after pressing **Tailscale에서 찾기**. Saving the
selected peer records its Node ID and DNS name, and a due Agent run resolves
that peer again before renewal.

## 5. Prepare a real-device run

Do these initial steps yourself before changing `--dry-run` to `--execute`:

1. Add your Apple Account to Xcode and identify your Personal Team ID.
2. Pair the iPhone with the Mac once, enable Developer Mode, and trust the Mac.
3. Give the sample a bundle identifier unique to your Personal Team.
4. Make the device visible to Xcode/CoreDevice.
5. Confirm the target UDID with the read-only command
   `xcrun devicectl list devices`.

For the experimental Tailnet route, running the live discovery command above
is an explicit user action. In Xcode, **Connect via IP Address** is still an
explicit initial user step. Pure-cellular CoreDevice connectivity is not
proven by these samples.

Once the prerequisites are verified, replace all placeholders and change only
the first argument from `--dry-run` to `--execute`. Execute mode:

1. calls `xcodebuild` with the target's configured signing settings,
   your selected team, and `-allowProvisioningUpdates`;
2. lets Xcode register the specified UDID if provisioning requires it;
3. clears only the expected output bundle, builds a new `.app` in a dedicated
   output directory, and checks its bundle identifier;
4. calls `xcrun devicectl device install app` for the specified UDID.

Execute mode can communicate with Apple, update local provisioning material,
write Derived Data, and replace the app on the iPhone. Test it manually before
enabling background renewal.

Each execute-mode renewal injects a new SideRefresh renewal ID and UTC build
time into the app bundle. When the sample opens, it compares that bundled ID
with the previously observed ID and automatically shows either
**SideRefresh 설치 확인됨** or **새 갱신 설치 확인됨**, together with the
current ID, previous ID, renewal build time, and this build's first-open time.

With **버전 그대로 유지**, SideRefresh does not override `MARKETING_VERSION`
or `CURRENT_PROJECT_VERSION`. With **자동으로 다음 버전**, execute mode first
reads Xcode's currently resolved build settings and the app version installed
on the iPhone, then advances each final numeric component. The **설치 확인
기록** button is a separate app-data persistence check. Its count and
last-check time are stored in the app container and are not used to decide
whether a new renewal was installed.
