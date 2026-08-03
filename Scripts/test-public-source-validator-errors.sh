#!/bin/bash

set -euo pipefail

repository_root="$(cd "$(dirname "$0")/.." && pwd)"
validator="$repository_root/Scripts/validate-public-source.sh"
snapshot_root="$(mktemp -d)"
trap 'rm -rf "$snapshot_root"' EXIT

if SIDEREFRESH_RG_COMMAND=/usr/bin/grep "$validator" >/dev/null 2>&1; then
    echo "Public source validation test failed: ripgrep error was accepted." >&2
    exit 1
fi

git -C "$repository_root" checkout-index --all --prefix="$snapshot_root/"
git -C "$snapshot_root" init -q
git -C "$snapshot_root" add .
mkdir -p "$snapshot_root/Sources"
private_identifier='com.'"recrack.private-app"
printf '%s\n' "$private_identifier" > "$snapshot_root/Sources/Private.swift"
git -C "$snapshot_root" add Sources/Private.swift
if SIDEREFRESH_PUBLIC_SOURCE_ROOT="$snapshot_root" \
    "$validator" >/dev/null 2>&1; then
    echo "Public source validation test failed: private source value was accepted." >&2
    exit 1
fi

git -C "$snapshot_root" rm -q -f Sources/Private.swift
stale_copy='저장소는 현재 pri'"vate입니다."
printf '%s\n' "$stale_copy" > "$snapshot_root/docs/Stale.md"
git -C "$snapshot_root" add docs/Stale.md
if SIDEREFRESH_PUBLIC_SOURCE_ROOT="$snapshot_root" \
    "$validator" >/dev/null 2>&1; then
    echo "Public source validation test failed: stale Korean copy was accepted." >&2
    exit 1
fi

git -C "$snapshot_root" rm -q -f docs/Stale.md
private_address='100.'"78.32.47"
printf '%s\n' "$private_address" > "$snapshot_root/Sources/Private.swift"
git -C "$snapshot_root" add Sources/Private.swift
if SIDEREFRESH_PUBLIC_SOURCE_ROOT="$snapshot_root" \
    "$validator" >/dev/null 2>&1; then
    echo "Public source validation test failed: private Tailnet IP was accepted." >&2
    exit 1
fi

private_ipv6='fd7a:115c:a1e0::'"5532:202f"
printf '%s\n' "$private_ipv6" > "$snapshot_root/Sources/Private.swift"
git -C "$snapshot_root" add Sources/Private.swift
if SIDEREFRESH_PUBLIC_SOURCE_ROOT="$snapshot_root" \
    "$validator" >/dev/null 2>&1; then
    echo "Public source validation test failed: private Tailnet IPv6 was accepted." >&2
    exit 1
fi

echo "Public source validator error tests passed"
