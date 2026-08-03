#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "$0")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
test_root="$(mktemp -d "${TMPDIR%/}/siderefresh-site-test.XXXXXX")"
source "$script_directory/public-site-validator-test-lib.sh"

uppercase_current_root="$(prepare_case uppercase-current)"
perl -0pi -e 's/aria-current="page"/ARIA-CURRENT="page"/' \
    "$uppercase_current_root/docs/index.html"
expect_accepted "$uppercase_current_root" "a valid uppercase current-language attribute"

misplaced_current_root="$(prepare_case misplaced-current)"
perl -0pi -e 's/href="\.\/" aria-current="page"/href=".\/"/; s/href="\.\/" aria-label/href=".\/" aria-current="page" aria-label/' \
    "$misplaced_current_root/docs/index.html"
expect_rejected "$misplaced_current_root" "a current-language marker outside the language navigation"

trailing_current_root="$(prepare_case trailing-current)"
perl -0pi -e 's/ aria-current="page"//; s#</ul></nav>#</ul></nav><nav><a href="./" aria-current="page">x</a></nav>#' \
    "$trailing_current_root/docs/index.html"
expect_rejected "$trailing_current_root" "a trailing current-language marker outside the language navigation"

wrong_language_root="$(prepare_case wrong-language)"
perl -0pi -e 's/href="\.\/" aria-current="page"/href=".\/"/; s/href="ko\/"/href="ko\/" aria-current="page"/' \
    "$wrong_language_root/docs/index.html"
expect_rejected "$wrong_language_root" "the wrong current language"

multiple_current_root="$(prepare_case multiple-current)"
perl -0pi -e 's/href="ko\/"/href="ko\/" ARIA-CURRENT="page"/' \
    "$multiple_current_root/docs/index.html"
expect_rejected "$multiple_current_root" "multiple current languages"

issue_link_root="$(prepare_case issue-link)"
private_issue_path="issues/999999"
private_issue_url="https://github.com/recrack/SideRefresh/$private_issue_path"
perl -0pi -e \
    "s#</footer>#<a href=\"$private_issue_url\">Internal</a></footer>#" \
    "$issue_link_root/docs/index.html"
expect_rejected "$issue_link_root" "a numbered issue link"

localized_download_root="$(prepare_case localized-download)"
perl -0pi -e 's#</footer>#<p>Mac용 다운로드</p></footer>#' \
    "$localized_download_root/docs/ko/index.html"
expect_rejected "$localized_download_root" "a localized premature download claim"

uppercase_script_root="$(prepare_case uppercase-script)"
perl -0pi -e 's#</footer>#<SCRIPT>void 0</SCRIPT></footer>#' \
    "$uppercase_script_root/docs/index.html"
expect_rejected "$uppercase_script_root" "an uppercase script element"

distorted_screenshot_root="$(prepare_case distorted-screenshot)"
perl -0pi -e 's/height: auto/height: 1400px/' \
    "$distorted_screenshot_root/docs/site/page.css"
expect_rejected "$distorted_screenshot_root" "a distorted product screenshot"

clean_root="$(prepare_case clean)"
"$clean_root/Scripts/validate-product-hunt-site.sh" >/dev/null
rg --fixed-strings --quiet 'social-preview-public-1280x640.png' \
    "$repository_root/Scripts/product-hunt-asset-privacy-checks.sh" \
    || { echo "Public social preview is missing from OCR validation." >&2; exit 1; }

echo "Public site validator self-tests passed"
