#!/bin/bash

set -euo pipefail

repository_root="$(cd "$(dirname "$0")/.." && pwd)"
hero="$repository_root/Assets/readme/hero.svg"

fail() {
    echo "Public homepage design test failed: $1" >&2
    exit 1
}

[[ -f "$hero" ]] || fail "README hero is missing"
rg --fixed-strings --quiet 'viewBox="0 0 1200 400"' "$hero" \
    || fail "README hero has the wrong canvas"
rg --quiet '<title[^>]*>SideRefresh' "$hero" \
    || fail "README hero has no accessible title"
rg --quiet '<desc[^>]*>' "$hero" \
    || fail "README hero has no accessible description"
rg --fixed-strings --quiet 'Assets/readme/hero.svg' "$repository_root/README.md" \
    || fail "README does not embed the hero"
rg --fixed-strings --quiet 'screenshots/en/healthy.png' "$repository_root/README.md" \
    || fail "README does not show the product proof"
rg --fixed-strings --quiet 'Sample preview · synthetic data' "$repository_root/README.md" \
    || fail "README does not qualify the fixture"

for page in docs/index.html docs/ko/index.html docs/ja/index.html docs/zh-cn/index.html; do
    rg --fixed-strings --quiet 'data-theme="renewal"' "$repository_root/$page" \
        || fail "$page does not use the renewal theme"
    rg --fixed-strings --quiet 'class="renewal-mark"' "$repository_root/$page" \
        || fail "$page does not include the SideRefresh motif"
    rg --fixed-strings --quiet '<meta name="theme-color" content="#050817">' \
        "$repository_root/$page" || fail "$page has no matching browser theme color"
    rg --fixed-strings --quiet 'fetchpriority="high"' "$repository_root/$page" \
        || fail "$page does not prioritize its product image"
done

rg --fixed-strings --quiet -- '--canvas: #050817' \
    "$repository_root/docs/site/theme.css" || fail "Pages palette is not project-native"
rg --fixed-strings --quiet 'touch-action: manipulation' \
    "$repository_root/docs/site/theme.css" || fail "Pages links do not declare touch behavior"
rg --fixed-strings --quiet 'scroll-margin-top:' \
    "$repository_root/docs/site/theme.css" || fail "Pages anchors do not clear the sticky header"
rg --fixed-strings --quiet 'html[lang="ko"] h1, html[lang="ko"] h2, html[lang="ko"] h3 { word-break: keep-all;' \
    "$repository_root/docs/site/theme.css" || fail "Korean headings can break inside words"
rg --fixed-strings --quiet 'html[lang="ko"] .hero h1 { font-size: clamp(3.1rem, 4.5vw, 4.1rem);' \
    "$repository_root/docs/site/theme.css" || fail "Korean hero heading wraps too aggressively on desktop"
rg --fixed-strings --quiet '.button.primary { border-color: var(--blue); color: var(--dark);' \
    "$repository_root/docs/site/components.css" || fail "Pages primary button contrast regressed"

echo "Public homepage design tests passed"
