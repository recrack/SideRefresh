# SideRefresh user manual

[English](MANUAL.md) | [한국어](MANUAL.ko.md)

SideRefresh keeps one iOS app that you own available on one iPhone by
rebuilding, signing, and reinstalling it before free Personal Team signing
expires.

It does not install third-party IPAs, bypass Apple signing, make a profile
permanent, sign in to Apple or Tailscale, or work without Xcode.

## Before opening SideRefresh

1. Install Xcode and add your Apple Account in **Xcode → Settings →
   Accounts**.
2. Open the app project, select its iOS application target, enable automatic
   signing, and choose your Personal Team.
3. Connect and unlock the iPhone, trust the Mac, and enable Developer Mode.
4. Pair the iPhone in **Xcode → Window → Devices and Simulators**.
5. Select the iPhone as the run destination and use **Product → Run** once.

That first Xcode run lets Apple create the local development signing assets
and completes the trust prompts that SideRefresh cannot perform for you. See
[Personal Team setup](PERSONAL-TEAM-SETUP.md) if Xcode shows no account or no
matching provisioning profile.

## 1. Choose your app

Open **Settings** from the Simple workspace and select **Choose app**.

The app picker replaces the content in the same Settings window. Search
locations appear as a one-line status summary by default; expand it only to
review paths, privacy details, or an access problem. The header and fixed
confirmation footer remain visible while those details expand.

Choose one `.xcworkspace` or `.xcodeproj`. Prefer the workspace when a project
uses CocoaPods or otherwise depends on workspace-level configuration. Before
confirming, review:

- app name and icon;
- Bundle ID and app version;
- iOS application target and scheme;
- Personal Team; and
- the exact Xcode container path.

SideRefresh reads Xcode project metadata and app icons for discovery. It does
not upload or edit source code. A highlighted result is only a proposal until
you confirm it in the fixed footer.

## 2. Choose one iPhone

Select **Choose iPhone**. SideRefresh reads Xcode's known-device list only
after this action.

Each candidate shows a friendly name, model when available, iOS version, and a
short identifier suffix. Select one device and press **Use selected iPhone**.
The full CoreDevice UDID remains the installation identity even when an
optional network address changes.

If no device appears, unlock the iPhone and check pairing in Xcode first.

## 3. Choose the connection preparation

The Xcode/CoreDevice card is always visible. **Check iPhone in Xcode** confirms
whether Xcode currently lists the selected device.

### No additional address

Use this for USB or a network path that Xcode already knows how to use. Xcode,
not SideRefresh, chooses the actual transport.

### Tailscale · Experimental

This option is for preparing a remote address. It requires a usable Tailscale
installation on the Mac and Tailscale on the iPhone, with both signed in to the
same tailnet.

1. Select **Tailscale · Experimental**.
2. If Tailscale is unavailable, install or open it and check again.
3. Select **Find iPhone** and choose a distinguishable peer. SideRefresh shows
   its device name (with a DNS fallback), preferred IP address, and a short
   stable node ID.
4. After **Tailscale address confirmed**, separately run **Check iPhone in
   Xcode**.

Tailscale online status is not proof of an Xcode connection. Tailscale does not
replace the CoreDevice UDID, initial pairing, trust, Developer Mode, or Apple
signing. Pure-cellular CoreDevice installation is not yet a verified public
support claim.

### Custom IP/DNS

Direct addresses remain in Advanced Settings for troubleshooting. Xcode may
need **Connect via IP Address** before it can use one.

## 4. Save Settings

The footer is fixed at the bottom of the Settings window:

- **Setup incomplete:** saving is disabled and the next required setup area is
  shown.
- **Save required:** the current draft can be applied with **Save settings** or
  **Save changes**.
- **Saved:** the app, iPhone, and connection choice are already active.

Selecting Tailscale blocks saving until a usable Mac installation and one
Tailnet iPhone are available. Closing a selector without confirming preserves
the prior draft.

## 5. Verify the first refresh

Return to **My app** and run **Refresh now**. Confirm the selected app and
iPhone. A real refresh:

1. checks the saved target and connection readiness;
2. runs an Xcode build with the selected Personal Team;
3. validates the built app's Bundle ID;
4. reads its embedded signing expiration;
5. installs it through CoreDevice; and
6. records success only after the required evidence exists.

Use Diagnostics to inspect raw Xcode and CoreDevice output. A successful
process exit without installation and expiration evidence is not shown as a
verified refresh.

## 6. Enable automatic refresh

Choose a refresh interval—144 hours (6 days) is recommended for a free
Personal Team—and decide whether to keep the current app version or advance
it. Save first, then explicitly enable **Automatic refresh**.

The background Agent is short-lived. The Mac must be awake, the project must
remain at its saved path, Xcode signing must still work, and the iPhone must be
reachable when a refresh is due.

## Reading the Simple workspace

The fixed left sidebar opens with **My app** selected and provides direct
routes to **Settings**, **Help**, and **Diagnostics**. These selections replace
the page inside the same launch window; they do not open additional windows.
The top header shows the current app on the left and a compact **Last
verified** time on the right. The scrollable home screen then shows, in order:

1. current refresh condition and at most one next action;
2. selected app → build, sign, install → selected iPhone;
3. next eligibility and recorded signing expiration;
4. current automatic-refresh and connection method; and
5. current progress or the most recent result.

Last verified evidence is historical proof, not a live connection indicator;
hover it or use VoiceOver for that qualification and the recorded expiration.

## Language

The Simple workspace, first-run Settings, and app/iPhone selectors include
English and Korean. Open **Settings → Language** and choose **Follow System
Settings**, **한국어**, or **English**. The default follows the preferred macOS
language for the app, and an explicit choice persists across launches. App
names, iPhone names, Bundle IDs, versions, addresses, identifiers, Diagnostics,
and external Xcode error output remain verbatim.

## Supported first-release scope

- one app owned by the user;
- one Xcode project or workspace;
- one paired physical iPhone;
- a Mac with Xcode and an Apple Account Personal Team.

Third-party IPA installation, multiple simultaneous apps or iPhones, users
without Xcode, and team fleet management are outside the first release.
