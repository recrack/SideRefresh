# Signed archive and provenance contract

> Decision artifact for Wayfinder #26.
>
> Current status: `v0.2.0-beta.2` is the source-only boundary. This document does not claim that a stable binary, final archive, or any gate currently passes.

## Authority and scope

`docs/research/public-release-maintenance-contract.md` is authoritative for version sequence, archive naming, package contents, release channels, and release gates. If this index conflicts with it, that document wins. This artifact records executable evidence and provenance; it intentionally does not restate those decisions.

`docs/release/first-release-acceptance-matrix.md` owns detailed real-device rows, case identity, route identity, and status aggregation. A fixture, simulator run, host-only build, or earlier archive never substitutes for final-archive evidence.

## Boundary and artifact identity

- The current distribution boundary is source-only `v0.2.0-beta.2`. An ad-hoc or unsigned local build is not a stable download and must not be presented as one.
- The stable universal candidate is exactly `SideRefresh-v0.2.0-universal-macos.zip`, and may use that name only after both `arm64` and `x86_64` slices are present and validated in the final archive.
- If universal validation is unavailable, publish only explicitly validated assets named `SideRefresh-v0.2.0-arm64-macos.zip` and/or `SideRefresh-v0.2.0-x86_64-macos.zip`. Never label a host-only binary `universal`; each architecture asset has its own evidence and checksum.
- Filename, archive bytes, and recorded checksum are one immutable identity. Any change after verification reopens every affected gate.

## Predecessor and upgrade/transition contract

Every stable release ledger must name one exact predecessor and transition. A
binary predecessor declaration includes the predecessor tag, architecture,
archive filename, and post-staple `archive_sha256`; a missing predecessor or
field is a failed gate. The only non-binary predecessor is the explicitly
identified source-only preview below: its exact source archive checksum is
required, while its architecture, archive, and post-staple fields are
explicitly `not-applicable`; it never supplies or implies a binary predecessor.

- **First stable `v0.2.0`:** The named transition is
  `source-preview-to-stable`, from the source-only `v0.2.0-beta.2` preview.
  Its predecessor identity must be recorded as the exact tag
  `v0.2.0-beta.2` and the exact source archive checksum recorded in
  `source_archive_sha256`; `architecture`, `archive_filename`, and
  post-staple `archive_sha256` are explicitly `not-applicable`. There is no
  binary predecessor. [DISTRIBUTION.md](../DISTRIBUTION.md) specifies no
  pre-release identifier migration layer, so this is not an in-place upgrade.
  With the preview installed, explicitly disable Automatic refresh
  (`side-refresh schedule disable --confirm` for Headless), verify that its
  Agent/launch registration is stopped, quit and uninstall/remove the preview
  app, then install the stable archive into fresh configuration, receipt,
  UserDefaults, and Agent state. The user's Xcode project and already
  installed iOS app remain untouched. Before stable setup, the expected state
  is no preview app, running schedule, or registration; after explicit user
  approval, the expected stable state is one registration, one selected target,
  and fresh evidence created from the final stable archive only. Any
  intentionally removed retained configuration/evidence is recorded in the
  uninstall record.
  The ordinary `upgrade` evidence status is `not-applicable`, never `pass`,
  with a mandatory justification naming the absent prior stable binary and the
  missing migration layer. The separate `source-preview-to-stable` transition
  evidence is mandatory and may be `pass` only when fresh final-stable-archive
  evidence covers disable/uninstall, fresh setup, explicit approval, and the
  expected pre- and post-setup states; otherwise publication is blocked.
- **Later stable releases:** The predecessor is the immediate prior stable tag
  and its exact architecture, archive filename, and post-staple archive digest,
  recorded as a named `stable-to-stable` transition. These binary predecessor
  fields are mandatory and may not be replaced with `not-applicable`. Pass
  requires the target, Last verified evidence, schedule state, and version/build
  to be preserved from that predecessor, with exactly one Agent registration
  after approval and no duplicate registration. The transition record must
  identify the target and predecessor/final archive digests; an advertised
  stable update without a passing transition record is not publishable.

## Signing contract

1. Use one intended **Developer ID Application** identity (not an installer identity) and record its certificate fingerprint.
2. Inventory every executable before signing. Sign nested Agent executables, helper executables/apps, and finally the outer SideRefresh app, inner first. Every inventoried executable must carry the approved identity, hardened-runtime flag, and secure timestamp.
3. Record reviewed entitlements and the signed path inventory. A missing, ad-hoc, differently signed, non-hardened, or non-timestamped nested object fails the candidate even when the outer app verifies.

## Verification sequence

Run these checks against the exact candidate that will be archived and retain their output with the release ledger:

| Gate | Required result |
| --- | --- |
| `codesign` | `codesign --verify --strict --verbose=4` succeeds for every nested object and the outer app; inspection shows Developer ID Application, runtime, and timestamp. Recursive verification is supplementary, not an inventory substitute. |
| Mach-O slices | For the exact post-staple final app, validate the Mach-O slices of the outer app and every nested executable in the signed-path inventory and record each result. Every advertised architecture must be present in every inventory entry. `universal` is valid only when every entry has both `arm64` and `x86_64`; otherwise publish only explicitly labelled `arm64` and/or `x86_64` assets whose every executable has that slice. |
| `notarytool` | `xcrun notarytool submit ... --wait` returns `Accepted`; retain submission ID and log. Rejection or unknown result blocks publication. |
| `stapler` | Staple the accepted ticket to the app; `xcrun stapler validate` succeeds on the stapled app; recreate the final ZIP only from that app. |
| `spctl` | `spctl --assess --type execute --verbose=4` accepts the extracted final app under normal Gatekeeper conditions; do not remove quarantine as a workaround. |
| SHA-256 | After stapling and final ZIP creation, hash the exact downloadable ZIP. Publish that post-staple digest, never a pre-staple or source-archive digest. |
| `attestation` | The final artifact attestation subject digest must equal the post-staple final `archive_sha256` byte-for-byte and must identify the canonical `repository`, `workflow`, immutable `ref`/release ref, and run. An independent verifier must verify the attestation against that exact archive, digest, `repository`/`workflow`/`ref`, and source commit; any identity, digest, or verification mismatch or unknown result blocks publication. |

Re-run relevant signing, notarization, stapler, and Gatekeeper checks when the app, archive, entitlements, identity, or toolchain changes.

## Provenance record

The release ledger and distributable provenance statement must contain at least:

| Field | Required value |
| --- | --- |
| `release_commit` | Full immutable source commit SHA. |
| `release_tag` | Exact tag including `v` (stable target: `v0.2.0`). |
| `predecessor` / `source_archive_sha256` | For first stable `v0.2.0`, the exact source-preview tag `v0.2.0-beta.2` and exact source archive checksum are required; predecessor `architecture`, `archive_filename`, and post-staple `archive_sha256` are explicitly `not-applicable`, with no binary predecessor implied. For later stable releases, the immediate prior stable tag, exact architecture, archive filename, and post-staple `archive_sha256` are mandatory. |
| `app_version` / `build_number` | `CFBundleShortVersionString` and monotonic `CFBundleVersion`. |
| `archive_filename` / `archive_sha256` | Exact final ZIP name and post-staple SHA-256. |
| `tool_versions` | macOS, Xcode, Swift, SDK, signing/notary tooling, and build-script versions. |
| `architecture` | `universal`, `arm64`, or `x86_64`, with slice-validation results. |
| `licenses` | SPDX license, `LICENSE`, `NOTICE`, and applicable third-party notices/SBOM. |
| `signing` / `notarization` | Certificate fingerprint, nested path inventory, notary submission ID/result, and stapler result. |
| `attestation` | Subject digest equal to the post-staple final `archive_sha256`, plus canonical `repository`, `workflow`, immutable `ref`/release ref and run identity, source commit, and independent verification command/result. |
| `evidence_refs` | Immutable links or hashes for clean-account and final-archive device evidence, explicit approval, the required upgrade/transition, and uninstall records; each resolves to the exact final archive identity. Missing or unverifiable refs fail closed. |

Do not include secrets, private keys, Apple credentials, provisioning profiles, UDIDs, or other private account material in the public statement.

## Acceptance evidence

Use the exact final archive and its recorded checksum for every case:

- **Clean-account launch:** download and verify the ZIP, extract it in a clean macOS account, launch normally, and record version/build and Gatekeeper result.
- **Approval:** complete Setup check and obtain explicit user approval for the background Agent/automatic renewal; verify that build or launch did not silently register it.
- **Upgrade/transition:** use the named predecessor declaration. For first stable `v0.2.0`, execute `source-preview-to-stable` exactly as defined above and retain a passing transition record; mark ordinary `upgrade` `not-applicable` only with the mandatory no-prior-stable/no-migration justification. For later stable releases, upgrade the immediate prior stable tag/architecture and pass only with preserved target/evidence, version/build, recovery path, and exactly one Agent registration with no duplicate.
- **Uninstall:** remove SideRefresh, its Agent/helper, and launch registration without deleting the user's Xcode project or installed iOS app; record intentionally removed retained evidence.
- **Final-archive real-device run:** with a physical paired iPhone, record Mac architecture, macOS, Xcode/Swift, iPhone/iOS build, route, archive name, and SHA-256. Exercise installation and the advertised renewal path and retain verified signing-expiration evidence. Simulator or prior-build results are not a pass.

## Fail-closed publication gate

The default state is `not-publishable`. Any missing, stale, mismatched, failed, or unverifiable field leaves the release at the source-only boundary; it is not a warning, inferred pass, or reason to disable Gatekeeper. A universal name is blocked until both slices and all required evidence validate; otherwise only separately validated architecture names may proceed.

Automation may build, test, assemble evidence, and hold a candidate. A human publisher must review the provenance record, compare the post-staple digest and attestation subject to the exact archive intended for publication, independently verify the repository/workflow/ref identity, inspect clean-account and real-device evidence, and review immutable refs for explicit approval, upgrade/transition, and uninstall. Missing or unverifiable evidence in any of those three mandatory categories fails closed; for `v0.2.0`, the ordinary `upgrade` `not-applicable` status also requires its named justification and a passing transition record. The publisher must explicitly authorize publication. Until that gate is recorded, no stable artifact is claimed as passing.
