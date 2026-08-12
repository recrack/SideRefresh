# Initial device baseline proposal

> Status: `pending human confirmation`.
>
> This is read-only candidate evidence from the tuple recorded in
> [Wayfinder issue #28](https://github.com/recrack/SideRefresh/issues/28). It
> is not a passed acceptance-matrix case, does not establish a support claim,
> and does not authorize publication.

## Candidate tuple

| Field | Candidate value |
| --- | --- |
| Mac model / architecture | MacBookPro18,2 / Apple M1 Max / `arm64` |
| macOS | `26.6.1`, build `25G76` |
| Xcode | `26.6`, build `17F113` |
| Swift | `6.3.3` |
| iPhone | iPhone 13 Pro Max (`iPhone14,3`) |
| iOS | `26.5.2`, build `23F84` |
| Pairing / Developer Mode | paired; Developer Mode enabled |
| Candidate route | cable/USB operating condition |
| CoreDevice tunnel | unavailable |

The route value is an operating-condition candidate, not proof that
SideRefresh detected USB transport. No UDID, serial number, Apple Account or
Team ID, provisioning profile, certificate, private path, credential, or other
private device data is recorded or intended for public release.

No `case_id` or `route_id` is created from this candidate yet. The acceptance
matrix requires the exact final archive filename and SHA-256 plus a complete
Swift toolchain identifier/build before an exact case and route record can be
created. The current CoreDevice-unavailable observation is not an executed
case. This candidate therefore does not prove minimum macOS/Xcode floor
compatibility or a `pass` for any `A-01`–`A-13` or `M-01`–`M-07` row.

## Proposed disposition

Keep this tuple as the initial device-baseline candidate only. Keep its matrix
records `blocked` or `not-run` until the exact final archive, real-device run,
route evidence, and required receipts exist. A candidate observation cannot be
carried forward as `pass` and cannot satisfy another case or route.

Read this proposal with the [first-release acceptance matrix](first-release-acceptance-matrix.md),
[first-release route policy](first-release-route-policy.md), and [signed archive
and provenance contract](signed-archive-provenance-contract.md).

## Exact human decision required

The named human must explicitly confirm:

> “I confirm this exact tuple as the proposed initial device baseline, with
> the first-release boundary limited to the cable-present operating condition;
> I understand it is read-only candidate evidence, not a passed matrix case
> or support claim, and that CoreDevice tunnel unavailability leaves the
> required execution blocked.”

This confirmation accepts the proposal for re-checking only. It does not mark
any matrix row `pass`, approve a final archive, or authorize publication.

## Re-check when the tunnel/device is available

1. Re-observe every tuple member on the same host and physical iPhone; record
   the exact final archive identity and immutable case/route records required
   by the [acceptance matrix](first-release-acceptance-matrix.md).
2. Re-establish and record the advertised cable-present route. If a
   CoreDevice tunnel is used, record it as a separately verified route; do not
   infer USB transport from command success or tunnel availability.
3. Against that exact final archive, run the applicable physical-device
   installation and renewal rows, including signing-expiration evidence,
   hands-free renewal across an iPhone reboot, route loss/recovery, and
   failure/retry behavior. Preserve the prior verified state on failure.
4. Verify archive checksum, signing, notarization/stapling, Gatekeeper, and
   provenance/attestation as required by the signed archive contract. Only
   complete exact-case/route evidence may change a record to `pass`; otherwise
   leave it `blocked`, `not-run`, or `fail` with the observed evidence.
