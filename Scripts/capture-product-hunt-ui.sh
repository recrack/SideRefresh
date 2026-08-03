#!/bin/bash

set -euo pipefail

mode="capture"
if (( $# == 1 )) && [[ "$1" = "--preview" ]]; then
    mode="preview"
elif (( $# != 0 )); then
    echo "Usage: $0 [--preview]" >&2
    exit 64
fi

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
output_directory="$repository_root/docs/product-hunt/assets/screenshots/en"
manifest="$repository_root/docs/product-hunt/assets/manifest.json"
source "$script_directory/product-hunt-asset-validation-lib.sh"
sample_icon="$repository_root/Examples/SideRefreshSampleApp/SideRefreshSample/Assets.xcassets/AppIcon.appiconset/SideRefresh-AppIcon.png"

required_commands=(codesign jq magick swift)
for command in "${required_commands[@]}"; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Required capture command not found: $command" >&2
        exit 69
    fi
done
test -f "$sample_icon"
test -x /usr/libexec/PlistBuddy

if [[ "$mode" = "capture" ]] && \
    ! assert_product_hunt_draft_capture_manifest "$manifest"; then
    exit 65
fi

capture_root="$(mktemp -d /tmp/siderefresh-marketing-capture.XXXXXX)"
capture_app="$capture_root/SideRefresh Capture.app"
cleanup() {
    rm -rf "$capture_root"
}
trap cleanup EXIT

swift build \
    --package-path "$repository_root" \
    --configuration debug \
    --product SideRefresh
binary_directory="$(
    swift build \
        --package-path "$repository_root" \
        --configuration debug \
        --show-bin-path
)"

mkdir -p \
    "$capture_app/Contents/MacOS" \
    "$capture_app/Contents/Resources" \
    "$output_directory"
install -m 755 \
    "$binary_directory/SideRefresh" \
    "$capture_app/Contents/MacOS/SideRefresh"
install -m 644 \
    "$repository_root/AppBundle/Info.plist" \
    "$capture_app/Contents/Info.plist"
/usr/libexec/PlistBuddy \
    -c 'Set :CFBundleIdentifier io.github.siderefresh.marketing-capture' \
    "$capture_app/Contents/Info.plist"
install -m 644 \
    "$repository_root/Assets/Brand/SideRefresh.icns" \
    "$capture_app/Contents/Resources/SideRefresh.icns"
/usr/bin/rsync -a \
    "$repository_root/AppBundle/Resources/" \
    "$capture_app/Contents/Resources/"
codesign --force --sign - --timestamp=none "$capture_app"

if [[ "$mode" = "preview" ]]; then
    open -n -W -a "$capture_app" \
        --env TZ=UTC \
        --env SIDEREFRESH_UI_FIXTURE=healthy \
        --env SIDEREFRESH_UI_FIXTURE_PREVIEW=1 \
        --env SIDEREFRESH_UI_FIXTURE_APP_ICON="$sample_icon" \
        --args \
        -AppleInterfaceStyle Dark \
        -AppleLocale en_US_POSIX \
        -ApplePersistenceIgnoreState YES \
        -side-refresh.language en
    exit 0
fi

fixtures=(
    healthy
    initial-setup
    dirty-target
    due
    running
    failure-with-evidence
)

for fixture in "${fixtures[@]}"; do
    output="$output_directory/$fixture.png"
    raw_output="$capture_root/$fixture-raw.png"
    TZ=UTC \
    SIDEREFRESH_UI_FIXTURE="$fixture" \
    SIDEREFRESH_UI_FIXTURE_OUTPUT="$raw_output" \
    SIDEREFRESH_UI_FIXTURE_APP_ICON="$sample_icon" \
        "$capture_app/Contents/MacOS/SideRefresh" \
        -AppleInterfaceStyle Dark \
        -AppleLocale en_US_POSIX \
        -ApplePersistenceIgnoreState YES \
        -side-refresh.language en
    if [[ ! -s "$raw_output" ]]; then
        echo "Missing fresh fixture capture: $fixture" >&2
        exit 1
    fi
    optimized="$capture_root/$fixture-optimized.png"
    magick "$raw_output" \
        -background '#1c1c1e' \
        -alpha remove \
        -alpha off \
        -strip \
        -colors 512 \
        "PNG8:$optimized"
    mv "$optimized" "$output"
    echo "$output"
done
