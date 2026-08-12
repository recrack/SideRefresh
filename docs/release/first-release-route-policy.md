# First-release route policy proposal

> Status: `pending human confirmation`.
>
> This is a release-policy proposal, not a support claim. No route is a stable
> claim until the exact final archive has the required evidence and a named
> human confirms the boundary.

## Proposed first-release route

Advertise the **Xcode/CoreDevice reachable operating envelope**. This covers
two operating conditions that use the same automatic path: a USB-connected
iPhone, or an iPhone already connected to Xcode over a local network. It names
the condition SideRefresh can rely on, not a transport that SideRefresh
detects:

- Manual setup is completed in Xcode: Apple Account/Personal Team, trust,
  Developer Mode, pairing, and the first run are user-controlled prerequisites.
- After setup, the selected physical iPhone remains reachable to Xcode and
  CoreDevice. The user may keep the cable connected or use a network route that
  Xcode already knows how to use.
- The approved Agent may perform scheduled automatic renewal with no user
  interaction under this proposed operating envelope. SideRefresh does not
  currently verify which transport Xcode selected.

If approved, public copy should say **“with the iPhone connected by USB or by
a network route already available to Xcode”**. It must not say “USB detected”,
“USB route detected”, or imply that SideRefresh identified or enforces the
physical transport. If only one condition completes the final-archive matrix,
the public wording must be narrowed to that condition.

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
The observable product boundary is therefore the Xcode/CoreDevice reachable
operating envelope, not a transport-detection result.

This is the narrowest honest first-release boundary: existing real-device
sample evidence was collected with a cable attached ([implementation status](../STATUS.md#verified-scope)),
while the release matrix requires evidence from the exact final archive and
exact device/toolchain for every advertised operating condition. That sample
does not prove detected USB transport or a local-network route. Personal Team
profiles and registered devices expire after seven days, so renewal still
requires a build, sign, and install cycle ([Apple Developer account overview](https://developer.apple.com/help/account/basics/about-your-developer-account)).

## Deferred and experimental routes

- Same-local-network CoreDevice is a candidate supported operating condition,
  not a passed route. It may be advertised only after a separate
  exact-final-archive run proves that route on a real device, with its own route
  descriptor and evidence; cable-route evidence does not transfer.
- Tailscale, Tailnet, direct-IP, and pure-cellular operation are omitted from
  first-release claims. Tailscale may still perform its experimental peer and
  address preflight, but it does not create or prove the Xcode/CoreDevice
  connection.
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

Human decision needed: confirm whether the first release advertises both USB
and separately verified same-local-network CoreDevice operation under this
reachable operating envelope, or narrows the wording to one condition. In
either case, keep Tailscale, direct-IP, and pure-cellular renewal outside the
stable claim until their own transport and lifecycle evidence exists.
