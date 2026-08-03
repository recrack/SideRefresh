#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
hooks_path=".githooks"
existing_hooks_path="$(
    git -C "$repository_root" config --local --get core.hooksPath \
        || true
)"

if [[ -n "$existing_hooks_path" && "$existing_hooks_path" != "$hooks_path" ]]
then
    echo "Existing core.hooksPath is '$existing_hooks_path'." >&2
    echo "Remove it explicitly before installing SideRefresh hooks." >&2
    exit 1
fi

test -x "$repository_root/.githooks/pre-commit"
test -x "$repository_root/.githooks/pre-push"

git -C "$repository_root" config --local core.hooksPath "$hooks_path"

echo "SideRefresh Git hooks installed from $hooks_path."
echo "pre-commit: staged diff check and conditional Swift tests"
echo "pre-push: Swift, samples, Headless, and Product Hunt assets"
