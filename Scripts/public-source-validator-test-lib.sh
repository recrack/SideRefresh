#!/bin/bash

expect_public_source_rejected() {
    local label="$1"
    if SIDEREFRESH_PUBLIC_SOURCE_ROOT="$fixture_root" \
        "$validator" >/dev/null 2>&1; then
        echo "Public source validation test failed: $label was accepted." >&2
        exit 1
    fi
}

create_public_source_fixture() {
    mkdir -p "$fixture_root/docs" "$fixture_root/.github/ISSUE_TEMPLATE" \
        "$fixture_root/.github/workflows"
    cp "$repository_root/LICENSE" "$repository_root/README.md" \
        "$repository_root/README.ko.md" "$repository_root/SECURITY.md" \
        "$repository_root/SUPPORT.md" "$repository_root/CODE_OF_CONDUCT.md" \
        "$repository_root/CONTRIBUTING.md" "$fixture_root/"
    cp "$repository_root/docs/ASSET-LICENSE.md" "$fixture_root/docs/"
    cp "$repository_root/.github/PULL_REQUEST_TEMPLATE.md" \
        "$repository_root/.github/dependabot.yml" "$fixture_root/.github/"
    cp "$repository_root/.github/ISSUE_TEMPLATE/"*.yml \
        "$fixture_root/.github/ISSUE_TEMPLATE/"
    printf '%s\n' \
        'steps:' \
        '  - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1' \
        > "$fixture_root/.github/workflows/ci.yml"
    printf '%s\n' \
        'steps:' \
        '  - uses: actions/configure-pages@45bfe0192ca1faeb007ade9deae92b16b8254a0d' \
        '  - uses: actions/upload-pages-artifact@fc324d3547104276b827a68afc52ff2a11cc49c9' \
        '  - uses: actions/deploy-pages@cd2ce8fcbc39b97be8ca5fce6e763baed58fa128' \
        > "$fixture_root/.github/workflows/pages.yml"
    git -C "$fixture_root" init -q
    git -C "$fixture_root" add .
}
