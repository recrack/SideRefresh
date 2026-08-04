#!/bin/bash

set -euo pipefail

repository_root="$(cd "$(dirname "$0")/.." && pwd)"
workflow="$repository_root/.github/workflows/pages.yml"
artifact_root="$(mktemp -d)/site"
trap 'rm -rf "${artifact_root%/site}"' EXIT

fail() {
    echo "Pages publication test failed: $1" >&2
    exit 1
}

[[ -f "$workflow" ]] || fail "Pages workflow is missing"
# shellcheck disable=SC2016
required_workflow_copy=(
    'branches: [master]'
    'contents: read'
    'pages: read'
    'pages: write'
    'id-token: write'
    'TMPDIR: ${{ runner.temp }}'
    'cancel-in-progress: false'
    'needs: build'
    "if: github.ref == 'refs/heads/master'"
    'name: github-pages'
    'url: ${{ steps.deployment.outputs.page_url }}'
    'include-hidden-files: true'
    'sudo apt-get install --no-install-recommends --yes ripgrep'
    'Scripts/validate-product-hunt-site.sh'
    'Scripts/test-public-site-validator.sh'
    'Scripts/test-public-homepage-design.sh'
    'Scripts/build-pages-site.sh'
    'Scripts/validate-pages-artifact.sh'
)
for copy in "${required_workflow_copy[@]}"; do
    rg --fixed-strings --quiet "$copy" "$workflow" || fail "workflow is missing: $copy"
done
rg --quiet '^\s*pull_request:' "$workflow" && fail "pull requests must not deploy"

site_validation_line="$(rg -n -m 1 'Scripts/validate-product-hunt-site.sh' "$workflow" | cut -d: -f1)"
artifact_build_line="$(rg -n -m 1 'Scripts/build-pages-site.sh' "$workflow" | cut -d: -f1)"
artifact_validation_line="$(rg -n -m 1 'Scripts/validate-pages-artifact.sh' "$workflow" | cut -d: -f1)"
artifact_upload_line="$(rg -n -m 1 'actions/upload-pages-artifact@' "$workflow" | cut -d: -f1)"
(( site_validation_line < artifact_build_line \
    && artifact_build_line < artifact_validation_line \
    && artifact_validation_line < artifact_upload_line )) \
    || fail "validation must finish before artifact upload"

required_actions=(
    'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1'
    'actions/configure-pages@45bfe0192ca1faeb007ade9deae92b16b8254a0d'
    'actions/upload-pages-artifact@fc324d3547104276b827a68afc52ff2a11cc49c9'
    'actions/deploy-pages@cd2ce8fcbc39b97be8ca5fce6e763baed58fa128'
)
for action in "${required_actions[@]}"; do
    rg --fixed-strings --quiet "uses: $action" "$workflow" || fail "action pin is missing: $action"
done
rg --fixed-strings --quiet '[[ ! -L "$source_path" ]]' \
    "$repository_root/Scripts/build-pages-site.sh" || fail "source symlink guard is missing"

"$repository_root/Scripts/build-pages-site.sh" "$artifact_root"
"$repository_root/Scripts/validate-pages-artifact.sh" "$artifact_root"

expected_files=(
    .nojekyll
    index.html
    ja/index.html
    ko/index.html
    product-hunt/assets/screenshots/en/healthy.png
    product-hunt/assets/social-preview-public-1280x640.png
    product-hunt/assets/thumbnail-240.png
    site/components.css
    site/page.css
    site/responsive.css
    site/theme.css
    zh-cn/index.html
)
actual_files=()
while IFS= read -r file; do actual_files+=("$file"); done < <(
    find "$artifact_root" -type f -print | sed "s|^$artifact_root/||" | sort
)
[[ "${actual_files[*]}" == "${expected_files[*]}" ]] || fail "artifact file set changed"

for file in "${expected_files[@]}"; do
    cmp "$repository_root/docs/$file" "$artifact_root/$file" >/dev/null \
        || fail "$file does not match its reviewed source"
done

touch "$artifact_root/unreviewed.txt"
if "$repository_root/Scripts/validate-pages-artifact.sh" "$artifact_root" >/dev/null 2>&1; then
    fail "artifact validator accepted an extra file"
fi

echo "Pages publication tests passed"
