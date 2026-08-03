#!/bin/bash

set -euo pipefail

application_path="${1:-}"
maximum_median_milliseconds="${2:-80}"
sample_count="${3:-9}"

if [[ ! -d "$application_path" ]]; then
    echo "Usage: $0 /path/to/SideRefresh.app [maximum-median-ms] [samples]" >&2
    exit 2
fi
if [[ ! "$maximum_median_milliseconds" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "Maximum median must be a nonnegative number." >&2
    exit 2
fi
if [[ ! "$sample_count" =~ ^[1-9][0-9]*$ ]]; then
    echo "Sample count must be a positive integer." >&2
    exit 2
fi

executable_path="$application_path/Contents/MacOS/SideRefresh"
if [[ ! -x "$executable_path" ]]; then
    echo "SideRefresh internal executable is missing: $executable_path" >&2
    exit 2
fi

expected_menu_labels=(
    "갱신 상태"
    "자동 갱신"
    "설정 테스트"
    "지금 갱신"
    "SideRefresh 열기"
    "종료"
)
for expected_menu_label in "${expected_menu_labels[@]}"; do
    if ! LC_ALL=C grep -aFq \
        "$expected_menu_label" \
        "$executable_path"
    then
        echo "Full menu label is missing: $expected_menu_label" >&2
        exit 1
    fi
done

measurements=()
for ((sample_index = 1; sample_index <= sample_count; sample_index += 1)); do
    osascript \
        -e 'tell application "SideRefresh" to quit' \
        >/dev/null 2>&1 || true
    for ((shutdown_check = 0; shutdown_check < 250; shutdown_check += 1)); do
        if ! pgrep -x SideRefresh >/dev/null; then
            break
        fi
        sleep 0.02
    done
    if pgrep -x SideRefresh >/dev/null; then
        pkill -x SideRefresh >/dev/null 2>&1 || true
    fi

    open -n "$application_path"
    measurement="$(
        osascript -l JavaScript <<'JXA'
ObjC.import("CoreGraphics")

const systemEvents = Application("System Events")
const sideRefresh = systemEvents.processes.byName("SideRefresh")

function findStatusItem() {
    if (!sideRefresh.exists()) {
        return null
    }
    const menuBars = sideRefresh.menuBars()
    if (menuBars.length < 2) {
        return null
    }
    const menuItems = sideRefresh.menuBars[1].menuBarItems()
    return menuItems.find(
        (item) => item.properties().description === "SideRefresh"
    ) || null
}

function findPopoverBounds() {
    const rawWindows = $.CGWindowListCopyWindowInfo(
        $.kCGWindowListOptionOnScreenOnly,
        $.kCGNullWindowID
    )
    const windows = ObjC.castRefToObject(rawWindows)
    const windowCount = Number(windows.count)
    for (
        let windowIndex = 0;
        windowIndex < windowCount;
        windowIndex += 1
    ) {
        const windowInfo = windows.objectAtIndex(windowIndex)
        const ownerName = ObjC.unwrap(
            windowInfo.objectForKey("kCGWindowOwnerName")
        )
        if (ownerName !== "SideRefresh") {
            continue
        }
        const bounds = ObjC.deepUnwrap(
            windowInfo.objectForKey("kCGWindowBounds")
        )
        if (bounds.Width >= 300 && bounds.Height >= 200) {
            return bounds
        }
    }
    return null
}

let statusItem = null
for (let check = 0; check < 500 && !statusItem; check += 1) {
    statusItem = findStatusItem()
    if (!statusItem) {
        delay(0.01)
    }
}
if (!statusItem) {
    throw new Error("SideRefresh menu bar item did not appear")
}

const startedAt = Date.now()
statusItem.click()
let popoverBounds = null
for (let check = 0; check < 500 && !popoverBounds; check += 1) {
    popoverBounds = findPopoverBounds()
    if (!popoverBounds) {
        delay(0.005)
    }
}
const elapsedMilliseconds = Date.now() - startedAt
if (!popoverBounds) {
    throw new Error("SideRefresh popover did not appear")
}

statusItem.click()
String(elapsedMilliseconds)
JXA
    )"
    measurements+=("$measurement")
    echo "sample $sample_index: ${measurement} ms"
done

median="$(
    printf '%s\n' "${measurements[@]}" \
        | sort -n \
        | awk -v count="$sample_count" '
            NR == int((count + 1) / 2) { lower = $1 }
            NR == int((count + 2) / 2) { upper = $1 }
            END {
                if (count % 2 == 1) {
                    print lower
                } else {
                    print (lower + upper) / 2
                }
            }
        '
)"

echo "median: ${median} ms (limit: ${maximum_median_milliseconds} ms)"
awk \
    -v measured="$median" \
    -v maximum="$maximum_median_milliseconds" \
    'BEGIN { exit measured <= maximum ? 0 : 1 }'
