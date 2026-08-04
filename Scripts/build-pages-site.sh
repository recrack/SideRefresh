#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "$0")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
# shellcheck source=Scripts/pages-artifact-files.sh
source "$script_directory/pages-artifact-files.sh"

[[ "$#" -eq 1 ]] || {
    echo "Usage: $0 OUTPUT_DIRECTORY" >&2
    exit 64
}

destination="$1"
[[ ! -e "$destination" ]] || {
    echo "Pages build failed: output already exists: $destination" >&2
    exit 73
}

mkdir -p "$destination"
for relative_path in "${pages_artifact_files[@]}"; do
    source_path="$repository_root/docs/$relative_path"
    [[ -f "$source_path" ]] || {
        echo "Pages build failed: missing source: docs/$relative_path" >&2
        exit 1
    }
    [[ ! -L "$source_path" ]] || {
        echo "Pages build failed: symbolic-link source: docs/$relative_path" >&2
        exit 1
    }
    mkdir -p "$destination/$(dirname "$relative_path")"
    cp "$source_path" "$destination/$relative_path"
done

echo "Pages artifact built at $destination"
