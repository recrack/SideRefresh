#!/bin/bash

while IFS= read -r entry; do
    if ! jq -e '
        (.path | type == "string" and length > 0)
        and (.source | type == "string" and length > 0)
        and (.status | type == "string" and length > 0)
        and (.width | type == "number" and . > 0)
        and (.height | type == "number" and . > 0)
        and has("replacementGate")
    ' <<<"$entry" >/dev/null; then
        echo "Manifest entry is incomplete." >&2
        exit 1
    fi
    asset_path="$(jq -r '.path' <<<"$entry")"
    asset_source="$(jq -r '.source' <<<"$entry")"
    asset_width="$(jq -r '.width' <<<"$entry")"
    asset_height="$(jq -r '.height' <<<"$entry")"
    check_product_hunt_dimensions "$asset_root/$asset_path" "$asset_width" "$asset_height"
    source_path="${asset_source%%\?*}"
    source_path="${source_path%%#*}"
    if [[ ! -e "$repository_root/$source_path" ]]; then
        echo "Manifest source does not exist: $asset_source" >&2
        exit 1
    fi
done < <(jq -c '.outputs[], .fixtureScreenshots[], .inputs[]' "$manifest")
