# First-release route policy proposal

> Status: `pending human confirmation`.
>
> This is a release-policy proposal, not a support claim. No route is a stable
> claim until the exact final archive has the required evidence and a named
> human confirms the boundary.

## Proposed first-release route

Advertise exactly one route: the **cable-present operating envelope**. This
names the required user operating condition, not a detected transport:

- Manual setup is completed in Xcode: Apple Account/Personal Team, trust,
  Developer Mode, pairing, and the first run are user-controlled prerequisites.
- After setup, the selected physical iPhone remains connected to the Mac by a
  cable.
- The approved Agent may perform scheduled automatic renewal with no user
  interaction under this proposed operating envelope. SideRefresh does not
  currently verify that the cable remains present.

If approved, public copy should say **“while you keep the iPhone connected by
cable”**. It must not say “USB detected”, “USB route detected”, or imply that
cable presence proves USB transport or that SideRefresh identified the physical
transport.

## Why this wording and boundary

The current code cannot attribute actual transport. `CoreDeviceReader` retains
the device UDID, name, OS version, and pairing state, but no USB/network field
([CoreDeviceReader.swift](../../Sources/SideRefreshCore/CoreDeviceReader.swift#L3-L16),
[CoreDeviceReader.swift](../../Sources/SideRefreshCore/CoreDeviceReader.swift#L101-L129)).
The renewal plan passes the same device identifier to `xcodebuild` and
`devicectl`; it does not select or report a transport
([IOSAppRenewalPlan.swift](../../Sources/SideRefreshCore/IOSAppRenewalPlan.swift#L175-L201),
[IOSAppRenewalPlan.swift](../../Sources/SideRefreshCore/IOSAppRenewalPlan.swift#L230-L245)).
This current UDID-only `xcodebuild`/`devicectl` invocation cannot enforce or
detect transport, enforce cable presence, or fail closed when a cable is
removed. This proposal makes no promise that cable loss fails closed. A
successful build/install while wireless CoreDevice remains available is not USB
evidence. A route claim therefore requires external evidence and/or a future
transport guard; command success alone is insufficient.
Apple also documents that Xcode uses a network-based interface for devices
attached by USB ([TN3158](https://developer.apple.com/documentation/technotes/tn3158-resolving-xcode-15-device-connection-issues)).
The observable product boundary is therefore the cable-present operating
envelope, not a transport-detection result.

This is the narrowest honest first-release boundary: existing real-device
sample evidence was collected with a cable attached ([implementation status](../STATUS.md#verified-scope)),
while the release matrix requires evidence from the exact final archive and
exact device/toolchain. That sample does not prove detected USB transport.
Personal Team profiles and
registered devices expire after seven days, so renewal still requires a build,
sign, and install cycle ([Apple Developer account overview](https://developer.apple.com/help/account/basics/about-your-developer-account)).

## Deferred and experimental routes

- Same-local-network CoreDevice is deferred. It may be advertised only after a
  separate exact-final-archive run proves that route on a real device, with its
  own route descriptor and evidence; cable-route evidence does not transfer.
- Tailscale, Tailnet, direct-IP, and pure-cellular operation are omitted from
  first-release claims. They are not alternate interpretations of the cabled
  route.
- The current UI still exposes some local-network, Tailscale/Tailnet, and
  direct-IP controls. This proposal does not claim those controls have already
  moved to **Experimental** Diagnostics; their visible controls and copy must
  be reconciled with this policy before approval.
- Any retained controls for these paths are experimental only. They must not
  appear as a supported route, satisfy the release matrix, or turn
  online/address/process-exit evidence into a Verified renewal.

## Required final-archive evidence

Every applicable **A-01..A-13** executable record and **M-01..M-06** minimum-
environment record in the [first-release acceptance matrix](first-release-acceptance-matrix.md)
is mandatory for the exact final archive, case, and advertised route. The
[signed archive and provenance contract](signed-archive-provenance-contract.md),
including its mandatory `source-preview-to-stable` transition for the first
stable release, the uninstall record, and the [human release gate](human-release-gate.md)
are also mandatory. These pointers do not replace any applicable matrix row or
field; examples of the non-exhaustive evidence set include clean-account
archive/provenance and Gatekeeper checks, explicit Agent approval, final-archive
physical-device installation/renewal with signing-expiration evidence, and
exact environment/archive identity. Fixtures, simulator runs, prior builds,
and host-only results do not qualify. A matrix record labelled USB remains an
operating-condition record here, not proof that SideRefresh detected USB;
route claims still require external evidence and/or a future transport guard.

## Authoritative connection references

- [Apple: Managing physical devices in Device Hub](https://developer.apple.com/documentation/xcode/pairing-your-devices-with-your-mac)
- [Apple: Pair a wireless device with Xcode](https://help.apple.com/xcode/mac/current/en.lproj/devbc48d1bad.html)
- [Apple: Run an app on a wireless device](https://help.apple.com/xcode/mac/current/en.lproj/dev3e2f4ee6d.html)
- [Apple TN3158: Resolving Xcode 15 device connection issues](https://developer.apple.com/documentation/technotes/tn3158-resolving-xcode-15-device-connection-issues)
- [Project connection-path terminology](../research/renewal-connection-path-terminology.md)

Human decision needed: confirm this single cable-present operating-envelope claim for the first release and defer LAN, direct-IP, Tailnet, Tailscale, and pure-cellular claims until separate evidence exists.
