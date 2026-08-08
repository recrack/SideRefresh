#!/bin/bash

private_pattern='/Users/[A-Za-z0-9._-]+|\b[A-Z0-9]{10}\b|\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}\b|\b[0-9A-Fa-f]{24,40}\b|\b([0-9]{1,3}\.){3}[0-9]{1,3}\b|\b(?i:[a-z0-9-]+\.tail[a-z0-9]+\.ts\.net)\b|\b(?i:[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,})\b|(?i:Apple Development:)'
extra_private_pattern="${SIDEREFRESH_PRIVATE_SCAN_PATTERN:-}"
stale_license_pattern='(?i:MIT[- ]licensed|MIT license|MIT라이センス|MIT 라이선스|MIT 许可证)'

ensure_product_hunt_paths_have_no_match \
    "$private_pattern" "$asset_root/source" "$asset_root/screenshots"
ensure_product_hunt_paths_have_no_match \
    "$stale_license_pattern" \
    "$asset_root/source/templates.js" "$asset_root/alt-text.md"
if [[ -n "$extra_private_pattern" ]]; then
    ensure_product_hunt_paths_have_no_match \
        "(?i:$extra_private_pattern)" "$asset_root/source" "$asset_root/screenshots"
fi

if command -v tesseract >/dev/null 2>&1; then
    ocr_text=""
    for image in \
        "$asset_root"/screenshots/en/*.png \
        "$asset_root"/gallery/*.png \
        "$asset_root"/social-preview-1280x640.png \
        "$asset_root"/social-preview-public-1280x640.png \
        "$asset_root"/demo/youtube-thumbnail-1280x720.png; do
        if ! image_text="$(tesseract "$image" stdout 2>&1)"; then
            echo "Tesseract OCR failed: $image" >&2
            echo "$image_text" >&2
            exit 69
        fi
        ocr_text+=$'\n'"$image_text"
    done
    ensure_product_hunt_text_has_no_match "$private_pattern" "$ocr_text"
    ensure_product_hunt_text_has_no_match "$stale_license_pattern" "$ocr_text"
    if [[ -n "$extra_private_pattern" ]]; then
        ensure_product_hunt_text_has_no_match \
            "(?i:$extra_private_pattern)" "$ocr_text"
    fi
elif [[ "$manifest_status" = "final" ]]; then
    echo "Final asset validation requires Tesseract OCR." >&2
    exit 69
else
    echo "Warning: Tesseract unavailable; draft OCR scan skipped." >&2
fi
