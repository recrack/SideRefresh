#!/bin/bash

load_public_source_paths() {
    public_source_paths=()
    local relative_path
    while IFS= read -r -d '' relative_path; do
        if [[ -f "$repository_root/$relative_path" \
            || -L "$repository_root/$relative_path" ]]; then
            public_source_paths+=("$repository_root/$relative_path")
        fi
    done < <(git -C "$repository_root" ls-files -z)

    [[ "${#public_source_paths[@]}" -gt 0 ]] || {
        echo "Public source validation failed: tracked tree is empty." >&2
        return 1
    }
}

reject_matches() {
    local description="$1"
    shift
    local matches
    local scan_status=0

    matches="$("$public_source_rg" -n --hidden "$@")" || scan_status=$?
    case "$scan_status" in
        0)
            echo "Public source validation failed: $description:" >&2
            echo "$matches" >&2
            return 1
            ;;
        1) return 0 ;;
        *)
            echo "Public source validation failed: ripgrep search error." >&2
            return "$scan_status"
            ;;
    esac
}

validate_public_source_contents() {
    reject_matches "direct internal tracker links found" \
        'https?://github\.com/recrack/SideRefresh/(issues|pull)/[0-9]+' \
        "${public_source_paths[@]}"
    reject_matches "bare internal tracker references found" -i -P \
        '\b(?:issue|tracking|tracker)\s*:?\s*\[?#[0-9]+' \
        "${public_source_paths[@]}"
    reject_matches "personal filesystem paths found" -P \
        '/Users/(?!YOU\b|example\b)[A-Za-z0-9._-]+' \
        "${public_source_paths[@]}"
    reject_matches "personal email addresses found" -i -P \
        '[A-Z0-9._%+-]+@(gmail\.com|naver\.com|daum\.net|kakao\.com|icloud\.com|me\.com|outlook\.com|hotmail\.com|yahoo\.com|protonmail\.com|fastmail\.com)' \
        "${public_source_paths[@]}"

    local tailnet_ipv4_allowlist
    local tailnet_ipv4_range
    tailnet_ipv4_allowlist='100\.64\.0\.(?:1|2|3|9|10|42)|100\.64\.10\.20|100\.92\.18\.12|100\.100\.100\.(?:42|99)'
    tailnet_ipv4_range='100\.(?:6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]{1,3}\.[0-9]{1,3}'
    reject_matches "private Tailnet IPv4 addresses found" -P \
        "\b(?!(?:${tailnet_ipv4_allowlist})\b)${tailnet_ipv4_range}\b" \
        "${public_source_paths[@]}"
    reject_matches "private Tailnet IPv6 addresses found" -i -P \
        '\bfd7a:115c:a1e0::(?!(?:1|2|42)\b)[0-9a-f:]+\b' \
        "${public_source_paths[@]}"
    reject_matches "private Tailnet DNS names found" -i \
        '[a-z0-9-]+\.tail[a-z0-9-]+\.ts\.net\.?' "${public_source_paths[@]}"
    reject_matches "private bundle identifiers found" -i \
        'com\.recrack\.[a-z0-9.-]+' "${public_source_paths[@]}"
    reject_matches "physical device identifiers found" -P \
        '\b(?!(?:00008110-001234567890001E|00008120-001234567890001E|00008120-001C2D123456A1B2)\b)[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}\b' \
        "${public_source_paths[@]}"

    local checkout_sha="3d3c42e5aac5ba805825da76410c181273ba90b1"
    reject_matches "actions/checkout must use $checkout_sha" -P \
        "uses:\\s*actions/checkout@(?!${checkout_sha}(?:\\s|$))\\S+" \
        "$repository_root/.github/workflows"
    reject_matches "stale repository-visibility copy found" -i \
        '(the |GitHub )?repository (is|remains) private|after (the )?repository is published|once (the )?repository is public|저장소는 (현재 )?(private|비공개)(입니다|이다)?' \
        "${public_source_paths[@]}"
}
