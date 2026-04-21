#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_ZIP="$SCRIPT_DIR/documents/selected-files.zip"
SKIP_MISSING=0

# Parse args (mirrors PS1: -SkipMissing switch)
for arg in "$@"; do
    case "$arg" in
        -SkipMissing|-skipmissing|--skip-missing) SKIP_MISSING=1 ;;
        *) OUTPUT_ZIP="$arg" ;;
    esac
done

# File list (backslash paths converted to forward slashes)
RELATIVE_PATHS=(
    '.claudeignore'
    '.dockerignore'
    'AGENTS.md'
    'CLAUDE.md'
    'DESIGN.md'
    'TODOS.md'
    'reset-and-build.bat'
    'reset-and-build.sh'
    'start-frontends.bat'
    'start-frontends.sh'
    'stop-frontends.bat'
    'stop-frontends.sh'
    'install-frontends.bat'
    'install-frontends.sh'
    'core-platform/deploy/.env'
    'rippleclio-admin-console/.env'
    'rippleclio-content/deploy/.env'
    'rippleclio-web/.env'
    'wabifair-admin-console/.env'
    'wabifair-commerce/deploy/.env'
    'wabifair-storefront-web/.env'
    'package-selected-files.bat'
    'package-selected-files.ps1'
    'package-selected-files.sh'
)

missing=()
files_to_pack=()

for rel in "${RELATIVE_PATHS[@]}"; do
    full="$SCRIPT_DIR/$rel"
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

# Ensure output directory exists
output_dir="$(dirname "$OUTPUT_ZIP")"
mkdir -p "$output_dir"

# Remove existing zip
[[ -f "$OUTPUT_ZIP" ]] && rm -f "$OUTPUT_ZIP"

# Build the zip from SCRIPT_DIR so relative paths are preserved
(
    cd "$SCRIPT_DIR"
    zip -q "${OUTPUT_ZIP}" "${files_to_pack[@]}"
)

echo "ZIP:$OUTPUT_ZIP"

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "WARNING: The following files do not exist and were skipped:" >&2
    for m in "${missing[@]}"; do echo "  $m" >&2; done
fi
