#!/bin/bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
expected_version="${1:-1.1}"
expected_build="${2:-7}"

fail() {
    printf 'Release validation failed: %s\n' "$1" >&2
    exit 1
}

setting() {
    local key="$1"
    printf '%s\n' "$build_settings" | awk -F ' = ' -v key="$key" '$1 ~ "^[[:space:]]*" key "$" { print $2; exit }'
}

check_screenshot_set() {
    local relative_dir="$1"
    local expected_width="$2"
    local expected_height="$3"
    local dir="$root/$relative_dir"
    local files=()
    local file metadata width height alpha format name index expected_prefix

    shopt -s nullglob
    files=("$dir"/*.png)
    shopt -u nullglob
    [[ ${#files[@]} -eq 5 ]] || fail "$relative_dir must contain exactly 5 PNG files"

    for index in "${!files[@]}"; do
        file="${files[$index]}"
        name="$(basename "$file")"
        [[ "$name" =~ ^[0-9][0-9]_.+\.png$ ]] || fail "$relative_dir/$name needs a numeric ordering prefix"
        expected_prefix="$(printf '%02d_' "$((index + 1))")"
        [[ "${name:0:3}" == "$expected_prefix" ]] ||
            fail "$relative_dir must use consecutive 01_ through 05_ screenshot prefixes"
        metadata="$(sips -g pixelWidth -g pixelHeight -g hasAlpha -g format "$file" 2>/dev/null)"
        width="$(printf '%s\n' "$metadata" | awk '/pixelWidth:/ { print $2 }')"
        height="$(printf '%s\n' "$metadata" | awk '/pixelHeight:/ { print $2 }')"
        alpha="$(printf '%s\n' "$metadata" | awk '/hasAlpha:/ { print $2 }')"
        format="$(printf '%s\n' "$metadata" | awk '/format:/ { print $2 }')"

        [[ "$width" == "$expected_width" && "$height" == "$expected_height" ]] ||
            fail "$relative_dir/$name is ${width}x${height}; expected ${expected_width}x${expected_height}"
        [[ "$alpha" == "no" ]] || fail "$relative_dir/$name must be opaque"
        [[ "$format" == "png" ]] || fail "$relative_dir/$name must be a PNG"
    done
}

build_settings="$(xcodebuild -project "$root/DailyLevels.xcodeproj" \
    -target DailyLevels -configuration Release -showBuildSettings)"

[[ "$(setting MARKETING_VERSION)" == "$expected_version" ]] || fail "marketing version is not $expected_version"
[[ "$(setting CURRENT_PROJECT_VERSION)" == "$expected_build" ]] || fail "build number is not $expected_build"
[[ "$(setting PRODUCT_BUNDLE_IDENTIFIER)" == "com.santipapmay.DailyLevels" ]] || fail "bundle ID changed"
[[ "$(setting INFOPLIST_KEY_ITSAppUsesNonExemptEncryption)" == "NO" ]] || fail "export-compliance setting changed"

check_screenshot_set "AppStore/screenshots/release_6_9" 1320 2868
check_screenshot_set "AppStore/screenshots/release_13_inch" 2064 2752

tracked_secrets="$(git -C "$root" ls-files | grep -E '\.(p8|p12|mobileprovision|ipa|xcarchive)$|(^|/)api_key\.json$|AuthKey_' || true)"
[[ -z "$tracked_secrets" ]] || fail "a signing key, profile, archive, or API credential is tracked"

storekit_config="$root/DailyLevels.storekit"
scheme="$root/DailyLevels.xcodeproj/xcshareddata/xcschemes/DailyLevels.xcscheme"
if ! storekit_values="$(ruby -rjson -e '
    config = JSON.parse(File.read(ARGV.fetch(0)))
    products = config.fetch("products")
    product = products.fetch(0)
    puts [products.length, product.fetch("productID"), product.fetch("type")].join("\t")
' "$storekit_config" 2>/dev/null)"; then
    fail "DailyLevels.storekit is not valid JSON"
fi
IFS=$'\t' read -r storekit_product_count storekit_product_id storekit_product_type <<< "$storekit_values"
[[ "$storekit_product_count" == "1" ]] ||
    fail "DailyLevels.storekit must contain exactly one product"
[[ "$storekit_product_id" == "com.santipapmay.DailyLevels.pro" ]] ||
    fail "DailyLevels.storekit has the wrong product ID"
[[ "$storekit_product_type" == "NonConsumable" ]] ||
    fail "Daily Levels Pro must be non-consumable"
grep -q 'identifier = "../../DailyLevels.storekit"' "$scheme" ||
    fail "the shared scheme is not using DailyLevels.storekit"

grep -q 'com\.santipapmay\.DailyLevels\.pro' "$root/DailyLevels/Store.swift" || fail "StoreKit product ID is missing from Store.swift"
grep -q 'com\.santipapmay\.DailyLevels\.pro' "$root/AppStore/METADATA.md" || fail "StoreKit product ID is missing from METADATA.md"

printf 'Release validation passed: Daily Levels %s (%s), 10 ordered screenshots, StoreKit config, no tracked secrets.\n' \
    "$expected_version" "$expected_build"
