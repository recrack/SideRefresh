#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
distribution_directory="$repository_root/dist"
application_path="$distribution_directory/SideRefresh.app"

if [[ "$application_path" != "$repository_root/dist/SideRefresh.app" ]]; then
    echo "Refusing unexpected application output path" >&2
    exit 1
fi

swift build \
    --package-path "$repository_root" \
    --configuration release \
    --product SideRefresh
swift build \
    --package-path "$repository_root" \
    --configuration release \
    --product SideRefreshAgent
swift build \
    --package-path "$repository_root" \
    --configuration release \
    --product SideRefreshIOSRenewal

binary_directory="$(
    swift build \
        --package-path "$repository_root" \
        --configuration release \
        --show-bin-path
)"

rm -rf "$application_path"
mkdir -p \
    "$application_path/Contents/MacOS" \
    "$application_path/Contents/Resources" \
    "$application_path/Contents/Resources/Samples" \
    "$application_path/Contents/Library/LaunchAgents"

install -m 755 \
    "$binary_directory/SideRefresh" \
    "$application_path/Contents/MacOS/SideRefresh"
install -m 755 \
    "$binary_directory/SideRefreshAgent" \
    "$application_path/Contents/Resources/SideRefreshAgent"
install -m 755 \
    "$binary_directory/SideRefreshIOSRenewal" \
    "$application_path/Contents/Resources/SideRefreshIOSRenewal"
install -m 644 \
    "$repository_root/AppBundle/Info.plist" \
    "$application_path/Contents/Info.plist"
install -m 644 \
    "$repository_root/Assets/Brand/SideRefresh.icns" \
    "$application_path/Contents/Resources/SideRefresh.icns"
install -m 644 \
    "$repository_root/Assets/Brand/SideRefresh-MenuBar.svg" \
    "$application_path/Contents/Resources/SideRefresh-MenuBar.svg"
for legal_file in LICENSE NOTICE BRAND_POLICY.md; do
    install -m 644 \
        "$repository_root/$legal_file" \
        "$application_path/Contents/Resources/$legal_file"
done
/usr/bin/rsync \
    -a \
    "$repository_root/AppBundle/Resources/" \
    "$application_path/Contents/Resources/"
install -m 644 \
    "$repository_root/AppBundle/LaunchAgents/io.github.siderefresh.renewal.plist" \
    "$application_path/Contents/Library/LaunchAgents/io.github.siderefresh.renewal.plist"
sample_destination="$application_path/Contents/Resources/Samples/SideRefreshSampleApp"
mkdir -p "$sample_destination"
/usr/bin/rsync \
    -a \
    --exclude 'build/' \
    --exclude 'xcuserdata/' \
    --exclude '*.xcuserstate' \
    "$repository_root/Examples/SideRefreshSampleApp/" \
    "$sample_destination/"

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

codesign \
    "${codesign_arguments[@]}" \
    "$application_path/Contents/Resources/SideRefreshAgent"
codesign --verify --strict "$application_path/Contents/Resources/SideRefreshAgent"
codesign \
    "${codesign_arguments[@]}" \
    "$application_path/Contents/Resources/SideRefreshIOSRenewal"
codesign --verify --strict \
    "$application_path/Contents/Resources/SideRefreshIOSRenewal"
codesign \
    "${codesign_arguments[@]}" \
    "$application_path"
codesign --verify --strict "$application_path"

echo "$application_path"
