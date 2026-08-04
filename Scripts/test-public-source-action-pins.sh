#!/bin/bash

set -euo pipefail

repository_root="$(cd "$(dirname "$0")/.." && pwd)"
validator="$repository_root/Scripts/validate-public-source.sh"
fixture_root="$(mktemp -d)"
trap 'rm -rf "$fixture_root"' EXIT
# shellcheck source=Scripts/public-source-validator-test-lib.sh
source "$repository_root/Scripts/public-source-validator-test-lib.sh"

create_public_source_fixture
action_pins=(
    'actions/checkout|3d3c42e5aac5ba805825da76410c181273ba90b1'
    'actions/configure-pages|45bfe0192ca1faeb007ade9deae92b16b8254a0d'
    'actions/upload-pages-artifact|fc324d3547104276b827a68afc52ff2a11cc49c9'
    'actions/deploy-pages|cd2ce8fcbc39b97be8ca5fce6e763baed58fa128'
)
for entry in "${action_pins[@]}"; do
    action="${entry%%|*}"
    sha="${entry#*|}"
    perl -pi -e "s/\\Q$sha\\E/v1/" "$fixture_root/.github/workflows/"*.yml
    expect_public_source_rejected "unpinned $action"
    git -C "$fixture_root" checkout -- .github/workflows
done

printf '%s\n' '  - uses: example/unreviewed-action@v1' \
    >> "$fixture_root/.github/workflows/pages.yml"
expect_public_source_rejected "new unpinned workflow action"

echo "Public source action pin tests passed"
