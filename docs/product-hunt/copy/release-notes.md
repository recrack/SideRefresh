# GitHub Release copy — first public launch

**Release title**

> SideRefresh [VERSION] — refresh one personal iOS app before signing expires

## What this release does

SideRefresh is an Apache-2.0-licensed Mac app for one Xcode project you own and one
paired iPhone. It rebuilds current local source, signs with your Xcode Personal
Team, validates the built app, reinstalls it through CoreDevice tooling, and
records verified installation and signing-expiration evidence.

## Requirements

- macOS 13 or later and Xcode 16.2 or a compatible Swift 6 toolchain;
- an Apple Account signed into Xcode with a Personal Team;
- a physical iPhone paired and trusted in Xcode with Developer Mode enabled;
- one successful Xcode installation before automatic refresh.

Paid Apple Developer Program membership is not required for personal-device
use. SideRefresh does not remove Apple's expiration or signing requirements.

## Install

1. Download `[FINAL ARCHIVE NAME]` and `[CHECKSUM FILE]` below.
2. Verify the SHA-256 value: `[EXACT COMMAND AND VALUE]`.
3. Verify Developer ID and notarization: `[VERIFICATION COMMANDS]`.
4. Move SideRefresh to Applications, open it, and follow the
   [English manual](https://github.com/recrack/SideRefresh/blob/master/docs/MANUAL.md)
   or [한국어 설명서](https://github.com/recrack/SideRefresh/blob/master/docs/MANUAL.ko.md).

Do not publish this release until a fresh external download passes checksum,
signature, notarization, Gatekeeper, launch, version, clean-account setup, first
installation, and subsequent refresh verification.

## Deliberate scope

- One user-owned app, one Xcode project/workspace, one paired iPhone.
- English and Korean Simple workspace and setup.
- Optional Tailscale discovery remains experimental.
- No third-party IPA installation, signing bypass, permanent profile, fleet or
  team management, or operation without Xcode.

## Support and safety

Read [known limitations](https://github.com/recrack/SideRefresh/blob/master/docs/STATUS.md)
before reporting a problem. Remove Apple
Account emails, paths, Team IDs, UDIDs, serials, IP/Tailnet data, certificates,
profiles, keys, and tokens from public reports.

Product Hunt: `[FULL PRODUCT HUNT URL AFTER LAUNCH]`

Apple, Mac, iPhone, macOS, and Xcode are trademarks of Apple Inc. SideRefresh
is independent and is not affiliated with, endorsed by, or sponsored by Apple.
