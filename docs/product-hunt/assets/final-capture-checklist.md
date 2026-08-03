# Release-candidate screenshot checklist

Use this only after the signed-release gate provides the exact public
SideRefresh release.
The automated fixture script is for draft composition and regression review;
it cannot prove the signed and notarized release binary.

## Prepare real sample evidence

- [ ] Record the release URL, commit, version, Developer ID signature check,
      notarization check, and SHA-256.
- [ ] Use the checked-in
      `Examples/SideRefreshSampleApp/SideRefreshSample.xcodeproj`, scheme
      `SideRefreshSample`, product `SideRefresh Sample`, and version `1.0 (1)`.
- [ ] Use a bundle identifier owned by the maintainer and safe to show, or crop
      it from public media. Never substitute a private project.
- [ ] Rename the test device `Demo iPhone`; hide every unrelated device.
- [ ] Run SideRefresh in English and dark appearance on a clean account.
- [ ] Complete one real install and one real subsequent refresh before capture.

## Capture

- [ ] Open the signed/notarized release, not a DEBUG fixture or prototype.
- [ ] Show only the Simple workspace and the checked-in Sample app relationship.
- [ ] Capture the workspace content at 2080×1400 pixels; do not stretch it.
- [ ] Replace only the public screenshot paths named by
      `manifest.json.finalization.publicReleaseCapturePaths`.
- [ ] Inspect every frame for account email, Team ID, certificate/profile data,
      paths, UDID, serial, IP address, Tailnet data, notifications, and logs.

## Promote the manifest

1. Copy `release-candidate-evidence.template.json` to
   `release-candidate-evidence.json`. Record the exact screenshot/app SHA-256,
   40-character release commit, version, UTC capture time, notarization request
   UUID, and successful signature/notarization checks. Do not reuse the
   template's pending values.
2. Change each replacement screenshot to status `release-candidate`, set
   `captureKind` to `signed-notarized-release-candidate`, record its SHA-256,
   set `releaseEvidence.evidencePath` to the completed evidence JSON, copy the
   same release facts into `releaseEvidence`, use a non-fixture `source`, and
   set `replacementGate` to `null`.
3. Change public outputs from `draft` to `final` and clear their gates.
4. Set top-level status to `final`, clear `releaseGate` to `null`, set
   `privacy.usesSyntheticData` to `false`, `removeDraftLabel` to `true`, and
   `replaceFixtureScreenshotsWithReleaseCandidateCaptures` to `false`.
5. Keep `publicReleaseCapturePaths` nonempty and limited to exact promoted
   screenshots. Run the validator with local known-value patterns. Final
   validation requires
   Tesseract OCR.
6. Render with the documented final attestation, inspect again, and rerun the
   validator before upload.

Do not promote the manifest merely to remove the draft badge.
