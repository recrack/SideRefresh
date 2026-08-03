#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
validation_directory="$(mktemp -d)"
configuration_path="$validation_directory/agent-config.json"
state_path="$validation_directory/renewal-state.json"
response_path="$validation_directory/mcp-responses.jsonl"

cleanup() {
    rm -rf "$validation_directory"
}
trap cleanup EXIT

for product in \
    side-refresh \
    SideRefreshAgent \
    SideRefreshIOSRenewal \
    siderefresh-mcp
do
    swift build \
        --package-path "$repository_root" \
        --product "$product"
done

binary_directory="$(
    swift build \
        --package-path "$repository_root" \
        --show-bin-path
)"

side_refresh_usage="$(
    "$binary_directory/side-refresh" 2>&1 || true
)"
[[ "$side_refresh_usage" == side-refresh:* ]]
[[ "$side_refresh_usage" == *"usage: side-refresh "* ]]

side_refresh_mcp_usage="$(
    "$binary_directory/siderefresh-mcp" --config relative 2>&1 || true
)"
[[ "$side_refresh_mcp_usage" == siderefresh-mcp:* ]]

"$binary_directory/side-refresh" \
    config \
    save \
    --config "$configuration_path" \
    --state-file "$state_path" \
    --helper "$binary_directory/SideRefreshIOSRenewal" \
    -- \
    --dry-run \
    --container \
    "$repository_root/Examples/SideRefreshSampleApp/SideRefreshSample.xcodeproj" \
    --scheme SideRefreshSample \
    --team ABCDE12345 \
    --bundle-id io.github.siderefresh.sample \
    --product SideRefreshSample \
    --device 00008110-001234567890001E \
    --derived-data "$validation_directory/DerivedData" \
    > /dev/null

"$binary_directory/side-refresh" \
    config show \
    --config "$configuration_path" \
    > /dev/null
"$binary_directory/side-refresh" \
    renewal status-config \
    --config "$configuration_path" \
    > /dev/null
"$binary_directory/side-refresh" \
    schedule status \
    --config "$configuration_path" \
    --agent "$binary_directory/SideRefreshAgent" \
    --plist "$validation_directory/io.github.siderefresh.renewal.plist" \
    > /dev/null

expect_failure() {
    if "$@" > /dev/null 2>&1; then
        echo "Expected command to fail: $*" >&2
        exit 1
    fi
}

expect_failure \
    "$binary_directory/side-refresh" \
    config show \
    --config "$configuration_path" \
    --config "$configuration_path"
expect_failure \
    "$binary_directory/side-refresh" \
    renewal run-now \
    --config "$configuration_path"
expect_failure \
    "$binary_directory/side-refresh" \
    schedule enable \
    --config "$configuration_path" \
    --agent "$binary_directory/SideRefreshAgent" \
    --plist "$validation_directory/io.github.siderefresh.renewal.plist" \
    --confirm

printf '%s\n' \
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"SideRefreshValidation","version":"1"}}}' \
    '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
    '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
    '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_status","arguments":{}}}' \
    '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"renew_now","arguments":{}}}' \
    '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"configure_target","arguments":{}}}' \
    | "$binary_directory/siderefresh-mcp" \
        --config "$configuration_path" \
        > "$response_path"

for response_index in 1 2 3 4 5; do
    /usr/bin/sed -n "${response_index}p" "$response_path" \
        > "$validation_directory/response-$response_index.json"
    test "$(
        plutil -extract jsonrpc raw \
            "$validation_directory/response-$response_index.json"
    )" = "2.0"
done

test "$(
    plutil -extract result.protocolVersion raw \
        "$validation_directory/response-1.json"
)" = "2025-11-25"
test "$(
    plutil -extract result.serverInfo.name raw \
        "$validation_directory/response-1.json"
)" = "siderefresh"
test "$(
    plutil -extract result.tools raw \
        "$validation_directory/response-2.json"
)" = "6"
test "$(
    plutil -extract result.isError raw \
        "$validation_directory/response-3.json"
)" = "false"
test "$(
    plutil -extract result.structuredContent.configured raw \
        "$validation_directory/response-3.json"
)" = "true"
test "$(
    plutil -extract result.isError raw \
        "$validation_directory/response-4.json"
)" = "true"
test "$(
    plutil -extract result.isError raw \
        "$validation_directory/response-5.json"
)" = "true"

echo "SideRefresh headless CLI, LaunchAgent plan, and MCP protocol validated."
