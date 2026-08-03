#!/bin/bash

assert_product_hunt_draft_capture_manifest() {
    local manifest="$1"
    if ! jq -e '
        .schemaVersion == 2
        and .status == "draft-pre-release"
        and .releaseGate == "signed-notarized-release"
        and ([.fixtureScreenshots[]]
            | length > 0
            and all(.status == "draft-fixture"
                and .captureKind == "debug-fixture"
                and .replacementGate
                    == "signed-release-candidate-capture"))
    ' "$manifest" >/dev/null; then
        echo "Draft capture refused: manifest is not draft-safe." >&2
        return 1
    fi
}

check_product_hunt_dimensions() {
    local file="$1"
    local expected_width="$2"
    local expected_height="$3"
    local width
    local height
    width="$(sips -g pixelWidth "$file" | awk '/pixelWidth/ {print $2}')"
    height="$(sips -g pixelHeight "$file" | awk '/pixelHeight/ {print $2}')"
    if [[ "$width" != "$expected_width" \
        || "$height" != "$expected_height" ]]; then
        echo "Unexpected dimensions: $file ($width x $height)" >&2
        return 1
    fi
}

ensure_product_hunt_paths_have_no_match() {
    local pattern="$1"
    shift
    local scan_status=0
    rg "$pattern" "$@" || scan_status=$?
    case "$scan_status" in
        0)
            echo "Potential private identifier found in asset inputs." >&2
            return 1
            ;;
        1) return 0 ;;
        *)
            echo "Private-data source scan failed." >&2
            return "$scan_status"
            ;;
    esac
}

ensure_product_hunt_text_has_no_match() {
    local pattern="$1"
    local content="$2"
    local scan_status=0
    rg -q "$pattern" <<<"$content" || scan_status=$?
    case "$scan_status" in
        0)
            echo "Potential private identifier found by image OCR." >&2
            return 1
            ;;
        1) return 0 ;;
        *)
            echo "Private-data OCR scan failed." >&2
            return "$scan_status"
            ;;
    esac
}

assert_product_hunt_final_manifest() {
    local manifest="$1"
    local asset_root="$2"
    local repository_root="$3"
    if ! jq -e '
        .schemaVersion == 2
        and .status == "final"
        and .releaseGate == null
        and .privacy.usesSyntheticData == false
        and .finalization.removeDraftLabel == true
        and (.finalization
            .replaceFixtureScreenshotsWithReleaseCandidateCaptures == false)
        and ([.outputs[] | select(.status != "reusable")]
            | all(.status == "final" and .replacementGate == null))
        and (.finalization.publicReleaseCapturePaths
            | type == "array"
            and length > 0
            and length == (unique | length))
    ' "$manifest" >/dev/null; then
        echo "Manifest release gates are not finalized." >&2
        return 1
    fi
    while IFS= read -r path; do
        local entry
        entry="$(jq -c --arg path "$path" '
            .fixtureScreenshots[] | select(.path == $path)
        ' "$manifest")"
        if [[ -z "$entry" ]] || ! jq -e '
            .status == "release-candidate"
            and .replacementGate == null
            and .captureKind == "signed-notarized-release-candidate"
            and (.source | test("capture-product-hunt-ui\\.sh") | not)
            and (.sha256 | test("^[0-9a-f]{64}$"))
            and (.releaseEvidence.commitSHA
                | test("^[0-9a-f]{40}$"))
            and (.releaseEvidence.version | length > 0)
            and (.releaseEvidence.capturedAt
                | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T"))
            and (.releaseEvidence.notarizationRequestId
                | test("^[0-9A-Fa-f-]{36}$"))
            and (.releaseEvidence.appBundleSHA256
                | test("^[0-9a-f]{64}$"))
            and (.releaseEvidence.operatorAttestation
                == "signed-release-approved")
            and (.releaseEvidence.evidencePath | length > 0)
        ' <<<"$entry" >/dev/null; then
            echo "Missing release-candidate capture evidence: $path" >&2
            return 1
        fi
        local expected_sha
        local actual_sha
        local evidence_path
        local commit_sha
        local version
        local captured_at
        local notary_id
        local app_sha
        expected_sha="$(jq -r '.sha256' <<<"$entry")"
        actual_sha="$(shasum -a 256 "$asset_root/$path" | awk '{print $1}')"
        evidence_path="$(jq -r '.releaseEvidence.evidencePath' <<<"$entry")"
        commit_sha="$(jq -r '.releaseEvidence.commitSHA' <<<"$entry")"
        version="$(jq -r '.releaseEvidence.version' <<<"$entry")"
        captured_at="$(jq -r '.releaseEvidence.capturedAt' <<<"$entry")"
        notary_id="$(jq -r '.releaseEvidence.notarizationRequestId' <<<"$entry")"
        app_sha="$(jq -r '.releaseEvidence.appBundleSHA256' <<<"$entry")"
        if [[ "$actual_sha" != "$expected_sha" \
            || ! -f "$repository_root/$evidence_path" ]]; then
            echo "Release evidence does not match capture: $path" >&2
            return 1
        fi
        if ! jq -e \
            --arg path "$path" \
            --arg screenshot_sha "$expected_sha" \
            --arg commit "$commit_sha" \
            --arg version "$version" \
            --arg captured_at "$captured_at" \
            --arg notary_id "$notary_id" \
            --arg app_sha "$app_sha" '
            .status == "release-candidate"
            and .screenshotPath == $path
            and .screenshotSHA256 == $screenshot_sha
            and .commitSHA == $commit
            and .version == $version
            and .capturedAt == $captured_at
            and .notarizationRequestId == $notary_id
            and .appBundleSHA256 == $app_sha
            and .signatureVerified == true
            and .notarizationVerified == true
            and .operatorAttestation == "signed-release-approved"
        ' "$repository_root/$evidence_path" >/dev/null; then
            echo "Release evidence record is invalid: $evidence_path" >&2
            return 1
        fi
    done < <(jq -r '.finalization.publicReleaseCapturePaths[]' "$manifest")
}
