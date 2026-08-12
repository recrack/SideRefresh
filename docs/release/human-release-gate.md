# Human release gate

> Status: `pending human decision`.
>
> No current stable artifact passes this gate. The repository remains at the
> source-only `v0.2.0-beta.2` boundary until a named human publisher records
> approval against one exact final archive.

This gate is the final human decision record for a stable public release. It
must be read with the [signed archive and provenance contract](signed-archive-provenance-contract.md),
the [first-release acceptance matrix](first-release-acceptance-matrix.md),
the [public release and maintenance contract](../research/public-release-maintenance-contract.md),
and [DISTRIBUTION.md](../DISTRIBUTION.md). Those documents own the detailed
contract, evidence schema, release sequence, and operational commands.

## Decision table

| Phase | Required decision and evidence | Result |
| --- | --- | --- |
| Before publish | Hold the candidate at `not-publishable`; build and inspect one exact final archive, checksum, provenance record, attestation, and acceptance-matrix ledger. | No public stable claim. |
| Authorize | A named human publisher independently verifies the exact bytes and every required gate, then records explicit approval for the exact tag, archive filename, and `archive_sha256`. | May publish one immutable release. |
| After publish | Verify the public download, checksum, signature, notarization/staple, Gatekeeper launch, provenance, and stable evidence. Record any incident and narrow or stop the claim when required. | Stable claim remains only while verification holds. |

## Pre-publish checklist

- [ ] The release tag is the intended immutable version, with a frozen source
      commit and monotonic build number; the tag and release are configured as
      immutable before publication.
- [ ] The exact final downloadable archive is named according to the contract:
      `SideRefresh-v0.2.0-universal-macos.zip`, or explicitly labelled
      `arm64`/`x86_64` when universal validation is unavailable.
- [ ] `archive_sha256` is computed from the exact post-staple ZIP to be
      uploaded; it is recorded in `SHA256SUMS` and the provenance ledger.
- [ ] The provenance record contains the full `release_commit`, exact
      `release_tag`, app/build numbers, archive filename and checksum,
      architecture/slice results, tool versions, licenses, signing identity
      fingerprint, nested signed-path inventory, notary submission/result,
      stapler result, and evidence references.
- [ ] Attestation subject digest equals the post-staple `archive_sha256` and
      identifies the canonical repository, workflow, immutable ref/release ref,
      run, and source commit; an independent verification result is retained.
- [ ] The archive contains the required license, notice, brand policy, release
      notes, compatibility/limitations, and complete uninstall instructions.
- [ ] Every required acceptance-matrix case and advertised route is explicitly
      enumerated for the final archive; no fixture, simulator, prior build, or
      host-only run is substituted.
- [ ] Matrix rows A-01 through A-13 are `pass`, except only an explicitly
      excluded `not-applicable` row with its required justification; no required
      record is `fail`, `blocked`, `not-run`, or `carried-forward`.
- [ ] Minimum environment rows M-01 through M-06 have the required final
      archive evidence; M-07 remains `not-applicable` only as an excluded
      experimental route. Exact iPhone model and iOS version/build are named.
- [ ] Final-archive clean-account launch, explicit Agent approval, USB/device
      renewal, each advertised route, and uninstall evidence are linked to the
      exact archive identity and redacted for public release.

## Human authorization

Automation may build, test, sign, notarize, assemble evidence, and hold a
candidate. It may not infer the publication decision. Before publishing, the
named human publisher must:

1. Compare the uploaded candidate bytes, filename, post-staple checksum, and
   attestation subject to the exact provenance record.
2. Independently verify signing, notarization, stapling, Gatekeeper, clean
   account launch, and final-archive physical-device evidence.
3. Confirm every required matrix status and the predecessor/transition record.
4. Confirm that the Agent was registered only after explicit user approval and
   that the approval evidence is immutable and linked.
5. Record: `I, <name>, authorize publication of <tag> / <archive_filename> /
   <archive_sha256> after reviewing the required evidence.` Include role,
   UTC timestamp, source commit, and an immutable evidence reference.

The Agent's approval is explicit and separate from the human publisher's
approval: the Agent may report readiness only after all automated checks and
evidence assembly succeed. Agent readiness is not authorization, and a human
publisher must still sign the decision above.

## Freeze, stop, and supersede rules

- Freeze the source commit, immutable tag, release metadata, archive bytes,
  checksum, provenance, and attestation before the human decision. Do not edit
  an immutable release, replace an asset, move a tag, or reuse a build number.
- Stop publication immediately on any checksum, filename, provenance, signing,
  notarization, stapling, Gatekeeper, clean-account, or physical-device failure,
  mismatch, rejection, unknown result, or unverifiable evidence. Keep the
  source-only boundary and record the failed gate.
- If a published immutable release needs correction, never edit it. Supersede
  it with a new version, new immutable tag, new archive/checksum/provenance,
  and a fresh human authorization; document the predecessor and transition.
- Product Hunt and other broad launch activity are allowed only after the
  stable release has passed post-publication download and verification checks.

## Public evidence handling

Publish only evidence needed to verify the claim. Redact Apple Account data,
Team IDs, UDIDs, device identifiers, Tailnet names/addresses, private paths,
profiles, certificates, credentials, private keys, tokens, and personal
contact data. Preserve enough sanitized logs, hashes, timestamps, environment
identity, archive identity, and immutable links for an independent verifier.

Until this document contains a completed named human authorization for one exact
final archive, the stable release is not approved and no binary is a passing
stable artifact.
