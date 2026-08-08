#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "$0")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
source "$script_directory/public-site-validation-data.sh"

fail() {
    echo "Public site validation failed: $1" >&2
    exit 1
}

for index in "${!pages[@]}"; do
    relative_page="${pages[$index]}"
    page="$repository_root/$relative_page"
    [[ -f "$page" ]] || fail "$relative_page is missing"
    required=(
        "html lang=\"${languages[$index]}\""
        "rel=\"canonical\" href=\"${canonicals[$index]}\""
        "${headlines[$index]}"
        "${app_languages[$index]}"
        "<main id=\"content\" tabindex=\"-1\">"
        "class=\"skip-link\" href=\"#content\""
        "${sample_labels[$index]}"
        "${license_labels[$index]}"
        "social-preview-public-1280x640.png"
        "https://github.com/recrack/SideRefresh/releases"
        "https://github.com/recrack/SideRefresh/blob/master/BRAND_POLICY.md"
        "<meta property=\"og:image:alt\""
        "<meta name=\"twitter:card\" content=\"summary_large_image\""
    )
    for copy in "${required[@]}"; do
        rg --fixed-strings --quiet "$copy" "$page" || fail "$relative_page is missing: $copy"
    done
    python3 "$script_directory/validate-public-site-language-nav.py" \
        "$page" "${current_language_hrefs[$index]}" \
        || fail "$relative_page has an invalid current-language marker"
    for alternate_index in "${!languages[@]}"; do
        alternate="hreflang=\"${languages[$alternate_index]}\" href=\"${canonicals[$alternate_index]}\""
        rg --fixed-strings --quiet "$alternate" "$page" || fail "$relative_page is missing $alternate"
    done
    rg --fixed-strings --quiet 'hreflang="x-default" href="https://recrack.github.io/SideRefresh/"' "$page" \
        || fail "$relative_page is missing x-default"
    page_directory="$(dirname "$page")"
    while IFS= read -r reference; do
        case "$reference" in http* | \#* | mailto:* | "") continue ;; esac
        clean_reference="${reference%%\#*}"
        [[ -e "$page_directory/$clean_reference" ]] || fail "$relative_page has a missing reference: $reference"
    done < <(rg --only-matching '(href|src)="[^"]+"' "$page" | sed -E 's/^(href|src)="//; s/"$//')
    while IFS= read -r anchor; do
        rg --fixed-strings --quiet "id=\"${anchor#\#}\"" "$page" || fail "$relative_page has a missing anchor: $anchor"
    done < <(rg --only-matching 'href="#[^"]+"' "$page" | sed -E 's/^href="//; s/"$//')
done

forbidden='(/Users/|file://|releases/latest|issues/[0-9]+|available now|download|다운로드|ダウンロード|下载|github_pat_|ghp_|BEGIN [A-Z ]*PRIVATE KEY|00008[0-9A-F]{3}-[0-9A-F]{16}|[A-Za-z0-9-]+\.ts\.net|DEVELOPMENT_TEAM=|[A-Za-z0-9._%+-]+@gmail\.com)'
if rg --ignore-case --line-number --regexp "$forbidden" "${pages[@]/#/$repository_root/}"; then
    fail "private, unsafe, or premature release content was found"
fi
if rg --ignore-case --quiet '<[[:space:]]*script\b|analytics|tracker|utm_' "${pages[@]/#/$repository_root/}"; then
    fail "scripts or tracking markers are not allowed"
fi
[[ -f "$repository_root/docs/product-hunt/assets/social-preview-public-1280x640.png" ]] || fail "public social preview is missing"
rg --fixed-strings --quiet '.product-frame img { display: block; width: 100%; height: auto;' \
    "$repository_root/docs/site/page.css" || fail "product screenshot must preserve its aspect ratio"
site_files=("${pages[@]}" "docs/site/theme.css" "docs/site/page.css" "docs/site/components.css" "docs/site/responsive.css" "Scripts/public-site-validation-data.sh" "Scripts/validate-public-site-language-nav.py" "Scripts/validate-product-hunt-site.sh")
for relative_file in "${site_files[@]}"; do
    file="$repository_root/$relative_file"
    [[ -f "$file" ]] || fail "$relative_file is missing"
    lines="$(wc -l < "$file" | tr -d ' ')"
    (( lines < 100 )) || fail "$(basename "$file") has $lines lines; split before 100"
done

echo "Public site validation passed"
