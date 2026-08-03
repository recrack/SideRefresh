# Support response bank — English

These are factual support answers for docs and owned channels. Product Hunt
comments must be answered personally rather than pasted from this file.

## Who is SideRefresh for?

People using Claude Code, Codex, Cursor, or Xcode to build a personal iOS app
they own and use on one paired iPhone outside App Store distribution.

## Does it remove Apple's expiration?

No. SideRefresh repeats Apple's normal development build, signing, validation,
and installation path before the current Personal Team signing expires.

## Do I need paid Apple Developer Program membership?

Not for personal-device use. You still need an Apple Account Personal Team,
Xcode, and Apple's required device setup. The public SideRefresh Mac binary has
a separate Developer ID signing and notarization requirement for distribution.

## What is required before automatic refresh?

A Mac with Xcode, an Apple Account signed into Xcode, the Personal Team selected
for the project, a physical iPhone paired and trusted, Developer Mode enabled,
and one successful Xcode installation. Then select the app and iPhone, save,
run one verified refresh, and explicitly enable automatic refresh.

## Does SideRefresh receive my Apple Account password?

No. Sign-in, agreements, certificates, pairing, trust, and Developer Mode stay
in Xcode and System Settings. Never send passwords, private keys, or complete
signing logs to support.

## Does it upload source code?

No. SideRefresh rebuilds the selected local source on the Mac with Xcode. It
does not pull Git changes or use a cloud signing service.

## Can it install third-party IPAs or manage several apps?

No. The first release supports one app you own from one selected Xcode project
or workspace and one paired iPhone. It is not an IPA store or fleet manager.

## What does the Tailscale option support?

It is optional and experimental. It can identify a selected Tailnet peer and
check a network route, but it does not replace Xcode pairing or prove
pure-cellular CoreDevice installation. Verify the first installation over USB.

## Why do I see “No Accounts” or “No profiles”?

Open Xcode, add the Apple Account under Xcode Settings → Accounts, open the
project, select the Personal Team for the app target, connect the iPhone, and
run the app once. SideRefresh does not create or repair Apple signing assets.

## What should I include in a bug report?

SideRefresh version, macOS and Xcode versions, project type, the exact visible
message, the failing stage, and sanitized diagnostics. Remove emails, paths,
Team IDs, UDIDs, serial numbers, IP/Tailnet data, certificates, profiles, and
tokens before posting publicly.
