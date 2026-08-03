#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "$0")" && pwd)"
script_root="$(cd "$script_directory/.." && pwd)"
repository_root="${SIDEREFRESH_PUBLIC_SOURCE_ROOT:-$script_root}"
public_source_rg="${SIDEREFRESH_RG_COMMAND:-rg}"
source "$script_directory/public-source-validation-lib.sh"

command -v "$public_source_rg" >/dev/null 2>&1 || {
    echo "Public source validation failed: ripgrep is required." >&2
    exit 69
}
if ! command -v git >/dev/null 2>&1 \
    || ! git -C "$repository_root" rev-parse \
        --is-inside-work-tree >/dev/null 2>&1; then
    echo "Public source validation failed: a Git worktree is required." >&2
    exit 69
fi

scratch_is_published=false
if command -v git >/dev/null 2>&1 && \
    git -C "$repository_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    [[ -z "$(git -C "$repository_root" ls-files -- .scratch)" ]] || \
        scratch_is_published=true
elif [[ -e "$repository_root/.scratch" ]]; then
    scratch_is_published=true
fi

[[ "$scratch_is_published" == false ]] || {
    echo "Public source validation failed: .scratch must not be published." >&2
    exit 1
}

required_files=(
    LICENSE
    README.md
    README.ko.md
    SECURITY.md
    SUPPORT.md
    CODE_OF_CONDUCT.md
    CONTRIBUTING.md
    docs/ASSET-LICENSE.md
    .github/ISSUE_TEMPLATE/bug-report.yml
    .github/ISSUE_TEMPLATE/feature-request.yml
    .github/ISSUE_TEMPLATE/config.yml
    .github/PULL_REQUEST_TEMPLATE.md
    .github/dependabot.yml
    .github/workflows/ci.yml
)

for relative_path in "${required_files[@]}"; do
    [[ -f "$repository_root/$relative_path" ]] || {
        echo "Public source validation failed: missing $relative_path" >&2
        exit 1
    }
done

load_public_source_paths
validate_public_source_contents

echo "Public source validation passed"
