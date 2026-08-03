#!/bin/bash

cleanup() {
    case "$test_root" in *siderefresh-site-test.*) rm -rf -- "$test_root" ;; esac
}
trap cleanup EXIT

prepare_case() {
    local case_name="$1"
    local case_root="$test_root/$case_name"
    mkdir -p "$case_root/Scripts" "$case_root/docs/product-hunt/assets/screenshots/en"
    cp "$repository_root/Scripts/validate-product-hunt-site.sh" "$case_root/Scripts/"
    cp "$repository_root/Scripts/public-site-validation-data.sh" "$case_root/Scripts/"
    cp "$repository_root/Scripts/validate-public-site-language-nav.py" "$case_root/Scripts/"
    cp "$repository_root/docs/index.html" "$case_root/docs/"
    cp -R "$repository_root/docs/site" "$repository_root/docs/ko" \
        "$repository_root/docs/ja" "$repository_root/docs/zh-cn" "$case_root/docs/"
    cp "$repository_root/docs/product-hunt/assets/social-preview-public-1280x640.png" \
        "$case_root/docs/product-hunt/assets/"
    cp "$repository_root/docs/product-hunt/assets/thumbnail-240.png" \
        "$case_root/docs/product-hunt/assets/"
    cp "$repository_root/docs/product-hunt/assets/screenshots/en/healthy.png" \
        "$case_root/docs/product-hunt/assets/screenshots/en/"
    printf '%s\n' "$case_root"
}

expect_rejected() {
    local case_root="$1"
    local reason="$2"
    if "$case_root/Scripts/validate-product-hunt-site.sh" >/dev/null 2>&1; then
        echo "Public site validator self-test failed: accepted $reason" >&2
        exit 1
    fi
}

expect_accepted() {
    local case_root="$1"
    local reason="$2"
    if ! "$case_root/Scripts/validate-product-hunt-site.sh" >/dev/null 2>&1; then
        echo "Public site validator self-test failed: rejected $reason" >&2
        exit 1
    fi
}
