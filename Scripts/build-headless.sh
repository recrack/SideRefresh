#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
distribution_directory="$repository_root/dist"
package_path="$distribution_directory/SideRefreshHeadless"
binary_output_path="$package_path/bin"
products=(
    side-refresh
    SideRefreshAgent
    SideRefreshIOSRenewal
    siderefresh-mcp
)

if [[ "$package_path" != "$repository_root/dist/SideRefreshHeadless" ]]; then
    echo "Refusing unexpected headless output path" >&2
    exit 1
fi

for product in "${products[@]}"; do
    swift build \
        --package-path "$repository_root" \
        --configuration release \
        --product "$product"
done

swift_binary_directory="$(
    swift build \
        --package-path "$repository_root" \
        --configuration release \
        --show-bin-path
)"

rm -rf "$package_path"
mkdir -p "$binary_output_path"

for executable in "${products[@]}"; do
    install -m 755 \
        "$swift_binary_directory/$executable" \
        "$binary_output_path/$executable"
done

signing_identity="${SIDEREFRESH_SIGNING_IDENTITY:--}"
codesign_arguments=(
    --force
    --sign "$signing_identity"
)
if [[ "$signing_identity" == "-" ]]; then
    codesign_arguments+=(--timestamp=none)
else
    codesign_arguments+=(--options runtime --timestamp)
fi

for executable in "${products[@]}"; do
    codesign \
        "${codesign_arguments[@]}" \
        "$binary_output_path/$executable"
    codesign --verify --strict "$binary_output_path/$executable"
done

echo "$package_path"
