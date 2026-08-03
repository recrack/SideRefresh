#!/bin/bash

sample_project="$(jq -r '.sampleApp.project' "$manifest")"
sample_product="$(jq -r '.sampleApp.product' "$manifest")"
sample_bundle="$(jq -r '.sampleApp.bundleIdentifier' "$manifest")"
sample_marketing="$(jq -r '.sampleApp.marketingVersion' "$manifest")"
sample_build="$(jq -r '.sampleApp.buildVersion' "$manifest")"
sample_icon="$(jq -r '.sampleApp.icon' "$manifest")"
fixture_source="$(jq -r '.sampleApp.fixtureSource' "$manifest")"
sample_pbxproj="$repository_root/$sample_project/project.pbxproj"

if [[ ! -f "$sample_pbxproj" || ! -f "$repository_root/$sample_icon" \
    || ! -f "$repository_root/$fixture_source" ]] || \
    ! rg -Fq "PRODUCT_BUNDLE_IDENTIFIER = $sample_bundle;" "$sample_pbxproj" || \
    ! rg -Fq "MARKETING_VERSION = $sample_marketing;" "$sample_pbxproj" || \
    ! rg -Fq "CURRENT_PROJECT_VERSION = $sample_build;" "$sample_pbxproj" || \
    ! rg -Fq "appName: \"$sample_product\"" "$repository_root/$fixture_source" || \
    ! rg -Fq "bundleIdentifier: \"$sample_bundle\"" "$repository_root/$fixture_source" || \
    ! rg -Fq "appVersion: \"$sample_marketing ($sample_build)\"" "$repository_root/$fixture_source"; then
    echo "Sample app and marketing fixture metadata have drifted." >&2
    exit 1
fi

case "$manifest_status" in
    draft-pre-release)
        jq -e '
            .releaseGate == "signed-notarized-release"
            and .privacy.usesSyntheticData == true
            and .finalization.removeDraftLabel == false
            and (.finalization.replaceFixtureScreenshotsWithReleaseCandidateCaptures == true)
            and ([.outputs[] | select(.status != "reusable")]
                | all(.status == "draft"
                    and .replacementGate
                        == "signed-release-candidate-capture"))
            and ([.fixtureScreenshots[]]
                | all(.status == "draft-fixture"
                    and .captureKind == "debug-fixture"
                    and .sha256 == null
                    and .releaseEvidence == null
                    and .replacementGate
                        == "signed-release-candidate-capture"))
        ' "$manifest" >/dev/null
        ;;
    final)
        assert_product_hunt_final_manifest "$manifest" "$asset_root" "$repository_root"
        ;;
    *)
        echo "Unsupported manifest status: $manifest_status" >&2
        exit 1
        ;;
esac
