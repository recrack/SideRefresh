#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
asset_root="$repository_root/docs/product-hunt/assets"
source_page="$asset_root/source/index.html"
playwright_command="$asset_root/source/node_modules/.bin/playwright"
manifest="$asset_root/manifest.json"
asset_status="${SIDEREFRESH_ASSET_STATUS:-draft}"
source "$script_directory/product-hunt-asset-validation-lib.sh"
required_commands=(jq magick shasum sips)
for command in "${required_commands[@]}"; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Required render command not found: $command" >&2
        exit 69
    fi
done
if [[ ! -x "$playwright_command" ]]; then
    echo "Pinned Playwright is missing; run npm ci in the asset source directory." >&2
    exit 69
fi
if [[ "$asset_status" != "draft" && "$asset_status" != "final" ]]; then
    echo "SIDEREFRESH_ASSET_STATUS must be draft or final." >&2
    exit 64
fi
if [[ "$asset_status" = "draft" ]]; then
    jq -e '.status == "draft-pre-release"' "$manifest" >/dev/null || {
        echo "Draft rendering requires a draft-pre-release manifest." >&2
        exit 65
    }
else
    if [[ "${SIDEREFRESH_FINAL_ASSET_ATTESTATION:-}" \
        != "signed-release-approved" ]]; then
        echo "Final rendering requires signed release approval." >&2
        exit 65
    fi
    assert_product_hunt_final_manifest \
        "$manifest" "$asset_root" "$repository_root" || exit 65
fi

mkdir -p "$asset_root/gallery" "$asset_root/demo"

render() {
    local asset="$1"
    local width="$2"
    local height="$3"
    local output="$4"
    "$playwright_command" screenshot \
        --browser chromium \
        --color-scheme dark \
        --viewport-size "$width,$height" \
        --wait-for-timeout 250 \
        "file://$source_page?asset=$asset&status=$asset_status" \
        "$output"
    magick "$output" -strip \
        -define png:compression-level=9 "$output"
    echo "$output"
}

sips --resampleHeightWidth 240 240 \
    "$repository_root/Assets/Brand/SideRefresh-AppIcon-1024.png" \
    --out "$asset_root/thumbnail-240.png" >/dev/null

render gallery-01 1270 760 "$asset_root/gallery/01-agent-builds.png"
render gallery-02 1270 760 "$asset_root/gallery/02-expiration-cycle.png"
render gallery-03 1270 760 "$asset_root/gallery/03-simple-workspace.png"
render gallery-04 1270 760 "$asset_root/gallery/04-xcode-flow.png"
render gallery-05 1270 760 "$asset_root/gallery/05-local-and-private.png"
render gallery-06 1270 760 "$asset_root/gallery/06-open-source.png"
render social-preview 1280 640 "$asset_root/social-preview-1280x640.png"
render youtube-thumbnail 1280 720 \
    "$asset_root/demo/youtube-thumbnail-1280x720.png"
