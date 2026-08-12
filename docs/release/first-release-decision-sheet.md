# First-release decision sheet

> Status: `pending human confirmation`.
>
> This sheet records the current Wayfinder proposals. It makes no stable
> support claim and does not authorize publication.

## Decisions requested

### 1. Route boundary — Wayfinder proposal

Confirm:

> “For the first release, advertise the **Xcode/CoreDevice reachable operating
> envelope**: after setup, the selected physical iPhone remains reachable to
> Xcode over USB or a separately verified network route already known to Xcode.
> SideRefresh does not verify or enforce the physical transport.”

This confirms the proposed wording and operating boundary only. It does **not**
approve USB transport detection, transport enforcement or fail-closed behavior;
it does not mark the USB or LAN route evidence as passed, and it does not
approve direct-IP, Tailnet/Tailscale, or pure-cellular routes, stable support,
or publication. See the [route policy](first-release-route-policy.md).

### 2. Device baseline — Wayfinder proposal

Confirm this read-only candidate tuple for re-checking:

| Field | Candidate |
| --- | --- |
| Mac | MacBookPro18,2 / Apple M1 Max / `arm64` |
| Host tools | macOS `26.6.1` / Xcode `26.6` / Swift `6.3.3` |
| Device | iPhone 13 Pro Max / iOS `26.5.2` |
| Route observation | USB observed; Xcode-known LAN condition still requires separate evidence |
| CoreDevice | Unavailable |

This confirms only the candidate baseline. It does **not** create an exact
case/route record, mark any `A-*` or `M-*` row `pass`, prove a minimum support
floor or USB detection, approve a final archive, establish stable support, or
authorize publication. See the [baseline proposal](initial-device-baseline-proposal.md).

### 3. Governance / human release gate — Wayfinder proposal

Confirm that a **named human publisher and recorded role** must independently
review the exact release evidence. Any integrity or device-gate failure,
mismatch, rejection, unknown result, or unverifiable evidence means stop and
make no announcement. An immutable release is never edited; a correction is
superseded by a new version with a new tag, archive, checksum, and evidence.
Broad launch activity, including Product Hunt, waits until post-publication
download and verification checks pass (see the [human release gate](human-release-gate.md)).

This governance confirmation does **not** authorize any current publication;
the exact-archive gate and separate final authorization remain required.

## Dependency order

1. Resolve the route and baseline Wayfinder proposals above.
2. Finalize and execute the [acceptance matrix](first-release-acceptance-matrix.md) against one exact archive, case, and advertised route.
3. Apply the [human release gate](human-release-gate.md); only a named human can authorize publication.

## Remaining evidence

- Exact final archive filename, SHA-256, tag/source commit, signing,
  notarization/stapling, Gatekeeper, provenance, and attestation.
- An exact case and route ledger, including the full Swift toolchain identity,
  archive identity, and redacted environment records.
- Complete required `A-01`–`A-13` and `M-01`–`M-06` evidence for every advertised
  USB or Xcode-known LAN route: physical-device install, hands-free renewal, signing-
  expiration, reboot, route loss/recovery, failure/retry, and uninstall.
- Re-check the candidate with the device/CoreDevice capability available;
  `CoreDevice unavailable` is currently a blocker, not a pass.
- Immutable, named-human confirmation for the two decisions above, followed
  by the separate final-archive authorization required by the human gate.

Until these records exist and the human gate is completed, the project remains
without a stable support or publication claim.
