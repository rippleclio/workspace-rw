#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
OUTPUT_ZIP="$ROOT_DIR/documents/selected-files.zip"
SKIP_MISSING=0

for arg in "$@"; do
    case "$arg" in
        -SkipMissing|-skipmissing|--skip-missing) SKIP_MISSING=1 ;;
        *) OUTPUT_ZIP="$arg" ;;
    esac
done

RELATIVE_PATHS=(
    'core-platform/deploy/.env'
    'rippleclio-admin-console/.env'
    'rippleclio-content/deploy/.env'
    'rippleclio-web/.env'
    'wabifair-admin-console/.env'
    'wabifair-commerce/deploy/.env'
    'wabifair-storefront-web/.env'
)

missing=()
files_to_pack=()

for rel in "${RELATIVE_PATHS[@]}"; do
    full="$ROOT_DIR/$rel"
    if [[ -f "$full" ]]; then
        files_to_pack+=("$rel")
    else
        missing+=("$rel")
    fi
done

if [[ ${#missing[@]} -gt 0 && $SKIP_MISSING -eq 0 ]]; then
    echo "ERROR: The following files do not exist. Packaging stopped:" >&2
    for m in "${missing[@]}"; do echo "  $m" >&2; done
    exit 1
fi

output_dir="$(dirname "$OUTPUT_ZIP")"
mkdir -p "$output_dir"

[[ -f "$OUTPUT_ZIP" ]] && rm -f "$OUTPUT_ZIP"

(
    cd "$ROOT_DIR"
    zip -q "$OUTPUT_ZIP" "${files_to_pack[@]}"
)

echo "ZIP:$OUTPUT_ZIP"

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "WARNING: The following files do not exist and were skipped:" >&2
    for m in "${missing[@]}"; do echo "  $m" >&2; done
fi
