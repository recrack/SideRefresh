#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "$0")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
# shellcheck source=Scripts/pages-artifact-files.sh
source "$script_directory/pages-artifact-files.sh"

fail() {
    echo "Pages artifact validation failed: $1" >&2
    exit 1
}

[[ "$#" -eq 1 ]] || fail "expected one artifact directory"
artifact_root="$1"
[[ -d "$artifact_root" ]] || fail "artifact directory is missing"
[[ -f "$artifact_root/index.html" ]] || fail "root index.html is missing"

if find "$artifact_root" -type l -print -quit | rg --quiet .; then
    fail "symbolic links are not allowed"
fi

expected_list="$(printf '%s\n' "${pages_artifact_files[@]}" | sort)"
actual_list="$(find "$artifact_root" -type f -print \
    | sed "s|^$artifact_root/||" | sort)"
[[ "$actual_list" == "$expected_list" ]] || fail "artifact file set changed"

for relative_path in "${pages_artifact_files[@]}"; do
    cmp "$repository_root/docs/$relative_path" \
        "$artifact_root/$relative_path" >/dev/null \
        || fail "$relative_path differs from its reviewed source"
done

echo "Pages artifact validation passed"
