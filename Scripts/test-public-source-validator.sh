#!/bin/bash

set -euo pipefail

repository_root="$(cd "$(dirname "$0")/.." && pwd)"
validator="$repository_root/Scripts/validate-public-source.sh"
fixture_root="$(mktemp -d)"
trap 'rm -rf "$fixture_root"' EXIT
# shellcheck source=Scripts/public-source-validator-test-lib.sh
source "$repository_root/Scripts/public-source-validator-test-lib.sh"

create_public_source_fixture

if ! rg -Fq 'python3 -m pytest' "$repository_root/.githooks/pre-push"; then
    echo "Public source validation test failed: pre-push omits Python tests." >&2
    exit 1
fi

if ! rg -Fq 'python3 -m venv "$RUNNER_TEMP/siderefresh-venv"' \
        "$repository_root/.github/workflows/ci.yml" \
    || ! rg -Fq '"$RUNNER_TEMP/siderefresh-venv/bin/python" -m pip install' \
        "$repository_root/.github/workflows/ci.yml" \
    || ! rg -Fq '"$RUNNER_TEMP/siderefresh-venv/bin/python" -m pytest' \
        "$repository_root/.github/workflows/ci.yml"; then
    echo "Public source validation test failed: CI does not isolate Python test dependencies." >&2
    exit 1
fi

SIDEREFRESH_PUBLIC_SOURCE_ROOT="$fixture_root" "$validator" >/dev/null

if PATH="/usr/bin:/bin" SIDEREFRESH_PUBLIC_SOURCE_ROOT="$fixture_root" \
    "$validator" >/dev/null 2>&1; then
    echo "Public source validation test failed: missing ripgrep was accepted." >&2
    exit 1
fi

rm "$fixture_root/SUPPORT.md"
if output="$(SIDEREFRESH_PUBLIC_SOURCE_ROOT="$fixture_root" "$validator" 2>&1)"; then
    echo "Public source validation test failed: missing SUPPORT.md was accepted." >&2
    exit 1
fi

[[ "$output" == *"missing SUPPORT.md"* ]] || {
    echo "Public source validation test failed: wrong missing-file diagnostic." >&2
    exit 1
}

cp "$repository_root/SUPPORT.md" "$fixture_root/SUPPORT.md"
rm "$fixture_root/NOTICE"
expect_public_source_rejected "missing NOTICE"
cp "$repository_root/NOTICE" "$fixture_root/NOTICE"

rm "$fixture_root/BRAND_POLICY.md"
expect_public_source_rejected "missing brand policy"
cp "$repository_root/BRAND_POLICY.md" "$fixture_root/BRAND_POLICY.md"

printf '%s\n' 'Not the Apache License' > "$fixture_root/LICENSE"
expect_public_source_rejected "invalid Apache license"
cp "$repository_root/LICENSE" "$fixture_root/LICENSE"

rm "$fixture_root/.github/workflows/ci.yml"
expect_public_source_rejected "missing CI workflow"
printf '%s\n' \
    'steps:' \
    '  - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1' \
    > "$fixture_root/.github/workflows/ci.yml"

rm "$fixture_root/.github/workflows/pages.yml"
expect_public_source_rejected "missing Pages workflow"
git -C "$fixture_root" checkout -- .github/workflows/pages.yml

rm "$fixture_root/CONTRIBUTING.md"
expect_public_source_rejected "missing contribution guide"
cp "$repository_root/CONTRIBUTING.md" "$fixture_root/CONTRIBUTING.md"

mkdir -p "$fixture_root/.scratch"
printf '%s\n' 'Assignee: local agent' > "$fixture_root/.scratch/internal.md"
git -C "$fixture_root" add .scratch/internal.md
expect_public_source_rejected ".scratch artifact"
git -C "$fixture_root" rm -q -r --cached .scratch
rm -rf "$fixture_root/.scratch"

private_issue_path="issues/999999"
private_issue_number="999999"
for test_case in \
    "direct tracker link|https://github.com/recrack/SideRefresh/$private_issue_path" \
    "bare tracker reference|Issue: #$private_issue_number" \
    'personal path|/Users/'"private-user/Projects/SecretApp" \
    'personal email|private.person@'"gmail.com" \
    'Tailnet DNS name|private-iphone.ta'"il123abc.ts.net." \
    'bundle identifier|com.'"recrack.private-app" \
    'device identifier|00008110-'"001A71182EC0401E" \
    'stale visibility copy|The repository is '"private."; do
    label="${test_case%%|*}"
    payload="${test_case#*|}"
    cp "$repository_root/README.md" "$fixture_root/README.md"
    printf '\n%s\n' "$payload" >> "$fixture_root/README.md"
    expect_public_source_rejected "$label"
done

echo "Public source validator tests passed"
"$repository_root/Scripts/test-public-source-action-pins.sh"
"$repository_root/Scripts/test-public-source-validator-errors.sh"
