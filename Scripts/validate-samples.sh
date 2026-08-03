#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
validation_directory="$repository_root/.build/sample-validation"
plan_path="$validation_directory/renewal-plan.json"
clean_plan_path="$validation_directory/clean-renewal-plan.json"
automatic_version_plan_path="$validation_directory/automatic-version-plan.json"
tailnet_path="$validation_directory/tailnet-discovery.json"
fingerprint_state_path="$validation_directory/fingerprint-state.json"
fingerprint_status_path="$validation_directory/fingerprint-status.json"
sample_products_directory="$validation_directory/SampleProducts"
sample_info_plist="$sample_products_directory/SideRefreshSample.app/Info.plist"
automatic_sample_products_directory="$validation_directory/AutomaticSampleProducts"
automatic_sample_info_plist="$automatic_sample_products_directory/SideRefreshSample.app/Info.plist"
sample_install_identifier="SR-0123456789AB"
sample_renewed_at="2001-02-03T04:05:06Z"

mkdir -p "$validation_directory"
rm -f "$fingerprint_state_path" "$fingerprint_status_path"

swift build \
    --package-path "$repository_root" \
    --product SideRefreshIOSRenewal
swift build \
    --package-path "$repository_root" \
    --product side-refresh

xcodebuild \
    -quiet \
    -project "$repository_root/Examples/SideRefreshSampleApp/SideRefreshSample.xcodeproj" \
    -scheme SideRefreshSample \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$validation_directory/DerivedData" \
    CONFIGURATION_BUILD_DIR="$sample_products_directory" \
    SIDEREFRESH_INSTALL_IDENTIFIER="$sample_install_identifier" \
    SIDEREFRESH_RENEWED_AT="$sample_renewed_at" \
    CODE_SIGNING_ALLOWED=NO \
    build

test "$(
    plutil -extract SideRefreshInstallIdentifier raw "$sample_info_plist"
)" = "$sample_install_identifier"
test "$(
    plutil -extract SideRefreshRenewedAt raw "$sample_info_plist"
)" = "$sample_renewed_at"
test "$(
    plutil -extract CFBundleShortVersionString raw "$sample_info_plist"
)" = "1.0"
test "$(
    plutil -extract CFBundleVersion raw "$sample_info_plist"
)" = "1"

build_arguments_contain() {
    local output_path="$1"
    local expected_argument="$2"
    local argument_count
    local argument_index

    argument_count="$(
        plutil -extract build_command.arguments raw "$output_path"
    )"
    for ((argument_index = 0; argument_index < argument_count; argument_index++)); do
        if [[ "$(
            plutil -extract \
                "build_command.arguments.$argument_index" \
                raw \
                "$output_path"
        )" = "$expected_argument" ]]; then
            return 0
        fi
    done
    return 1
}

validate_renewal_plan() {
    local strategy="$1"
    local output_path="$2"
    local first_action="$3"
    local second_action="${4:-}"
    local argument_count
    local action_index

    "$repository_root/.build/debug/SideRefreshIOSRenewal" \
        --dry-run \
        --build-strategy "$strategy" \
        --version-policy keep \
        --container \
        "$repository_root/Examples/SideRefreshSampleApp/SideRefreshSample.xcodeproj" \
        --scheme SideRefreshSample \
        --team ABCDE12345 \
        --bundle-id io.github.siderefresh.sample \
        --product SideRefreshSample \
        --device 00008110-001234567890001E \
        --derived-data "$validation_directory/DeviceDerivedData" \
        > "$output_path"

    test "$(plutil -extract mode raw "$output_path")" = "dry-run"
    test "$(
        plutil -extract build_strategy raw "$output_path"
    )" = "$strategy"
    test "$(
        plutil -extract version_policy raw "$output_path"
    )" = "keep"
    test "$(
        plutil -extract system_changes_performed raw "$output_path"
    )" = "false"
    argument_count="$(
        plutil -extract build_command.arguments raw "$output_path"
    )"
    action_index=$((argument_count - 1))
    if [[ -n "$second_action" ]]; then
        test "$(
            plutil -extract \
                "build_command.arguments.$action_index" \
                raw \
                "$output_path"
        )" = "$second_action"
        action_index=$((action_index - 1))
    fi
    test "$(
        plutil -extract \
            "build_command.arguments.$action_index" \
            raw \
            "$output_path"
    )" = "$first_action"
    build_arguments_contain \
        "$output_path" \
        "SIDEREFRESH_INSTALL_IDENTIFIER=$(
        plutil -extract renewal_evidence.identifier raw "$output_path"
    )"
    build_arguments_contain \
        "$output_path" \
        "SIDEREFRESH_RENEWED_AT=$(
        plutil -extract renewal_evidence.renewed_at raw "$output_path"
    )"
}

validate_renewal_plan incremental "$plan_path" build
validate_renewal_plan \
    clean-rebuild \
    "$clean_plan_path" \
    clean \
    build

"$repository_root/.build/debug/SideRefreshIOSRenewal" \
    --dry-run \
    --build-strategy incremental \
    --version-policy automatic \
    --container \
    "$repository_root/Examples/SideRefreshSampleApp/SideRefreshSample.xcodeproj" \
    --scheme SideRefreshSample \
    --team ABCDE12345 \
    --bundle-id io.github.siderefresh.sample \
    --product SideRefreshSample \
    --device 00008110-001234567890001E \
    --derived-data "$validation_directory/AutomaticDeviceDerivedData" \
    > "$automatic_version_plan_path"

test "$(
    plutil -extract version_policy raw "$automatic_version_plan_path"
)" = "automatic"
test "$(
    plutil -extract resolved_app_version.marketing_version raw \
        "$automatic_version_plan_path"
)" = "1.1"
test "$(
    plutil -extract resolved_app_version.build_version raw \
        "$automatic_version_plan_path"
)" = "2"
build_arguments_contain \
    "$automatic_version_plan_path" \
    "MARKETING_VERSION=1.1"
build_arguments_contain \
    "$automatic_version_plan_path" \
    "CURRENT_PROJECT_VERSION=2"

xcodebuild \
    -quiet \
    -project "$repository_root/Examples/SideRefreshSampleApp/SideRefreshSample.xcodeproj" \
    -scheme SideRefreshSample \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$validation_directory/AutomaticDerivedData" \
    CONFIGURATION_BUILD_DIR="$automatic_sample_products_directory" \
    MARKETING_VERSION=1.1 \
    CURRENT_PROJECT_VERSION=2 \
    SIDEREFRESH_INSTALL_IDENTIFIER="$sample_install_identifier" \
    SIDEREFRESH_RENEWED_AT="$sample_renewed_at" \
    CODE_SIGNING_ALLOWED=NO \
    build

test "$(
    plutil -extract CFBundleShortVersionString raw \
        "$automatic_sample_info_plist"
)" = "1.1"
test "$(
    plutil -extract CFBundleVersion raw "$automatic_sample_info_plist"
)" = "2"

"$repository_root/.build/debug/side-refresh" \
    tailnet discover \
    --status-file \
    "$repository_root/Examples/Tailnet/tailscale-status.sample.json" \
    > "$tailnet_path"

test "$(
    plutil -extract devices.0.preferred_ip_address raw "$tailnet_path"
)" = "100.64.0.2"
test "$(
    plutil -extract system_changes_performed raw "$tailnet_path"
)" = "false"

"$repository_root/.build/debug/side-refresh" \
    renewal run-due \
    --state-file "$fingerprint_state_path" \
    -- /usr/bin/true --dry-run \
    > /dev/null

"$repository_root/.build/debug/side-refresh" \
    renewal status \
    --state-file "$fingerprint_state_path" \
    -- /usr/bin/true --execute \
    > "$fingerprint_status_path"

test "$(plutil -extract due raw "$fingerprint_status_path")" = "true"
test "$(
    plutil -extract command.arguments.0 raw "$fingerprint_status_path"
)" = "--execute"

echo "SideRefresh samples validated without signing or device installation."
