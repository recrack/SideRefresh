#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
asset_root="$repository_root/docs/product-hunt/assets"
manifest="$asset_root/manifest.json"
evidence_template="$asset_root/release-candidate-evidence.template.json"

source "$script_directory/product-hunt-asset-validation-lib.sh"
source "$script_directory/product-hunt-asset-basic-checks.sh"
source "$script_directory/product-hunt-asset-privacy-checks.sh"
source "$script_directory/product-hunt-asset-manifest-checks.sh"
source "$script_directory/product-hunt-sample-manifest-checks.sh"

echo "Product Hunt asset validation passed."
