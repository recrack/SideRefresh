#!/bin/bash

required_commands=(jq rg shasum sips stat)
for required_command in "${required_commands[@]}"; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        echo "Required validation command not found: $required_command" >&2
        exit 69
    fi
done

jq -e . "$manifest" >/dev/null
jq -e '.schemaVersion == 2' "$manifest" >/dev/null
jq -e '
    .status == "template-do-not-promote"
    and .signatureVerified == false
    and .notarizationVerified == false
    and .operatorAttestation == "pending-signed-release"
' "$evidence_template" >/dev/null
manifest_status="$(jq -r '.status' "$manifest")"

check_product_hunt_dimensions "$asset_root/thumbnail-240.png" 240 240
check_product_hunt_dimensions "$asset_root/social-preview-1280x640.png" 1280 640
check_product_hunt_dimensions "$asset_root/social-preview-public-1280x640.png" 1280 640
check_product_hunt_dimensions "$asset_root/demo/youtube-thumbnail-1280x720.png" 1280 720

gallery_files=(
    "$asset_root/gallery/01-agent-builds.png"
    "$asset_root/gallery/02-expiration-cycle.png"
    "$asset_root/gallery/03-simple-workspace.png"
    "$asset_root/gallery/04-xcode-flow.png"
    "$asset_root/gallery/05-local-and-private.png"
    "$asset_root/gallery/06-open-source.png"
)
for gallery_file in "${gallery_files[@]}"; do
    check_product_hunt_dimensions "$gallery_file" 1270 760
done

thumbnail_size="$(stat -f %z "$asset_root/thumbnail-240.png")"
if (( thumbnail_size >= 3 * 1024 * 1024 )); then
    echo "Thumbnail must stay below 3 MB." >&2
    exit 1
fi
for social_preview in "$asset_root/social-preview-1280x640.png" "$asset_root/social-preview-public-1280x640.png"; do
    if (( $(stat -f %z "$social_preview") >= 1024 * 1024 )); then
        echo "Social previews must stay below 1 MB." >&2
        exit 1
    fi
done
