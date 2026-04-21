#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "============================================"
echo "  Workspace first-time setup"
echo "============================================"
echo

if ! command -v git > /dev/null 2>&1; then
  echo "git is required but was not found in PATH."
  exit 1
fi

if ! command -v npm > /dev/null 2>&1; then
  echo "npm is required but was not found in PATH."
  exit 1
fi

echo "[1/2] Install frontend dependencies"
bash "$SCRIPT_DIR/install-frontends.sh"

echo "[2/2] Verify repository layout"
for repo in \
  core-platform \
  documents \
  rippleclio-admin-console \
  rippleclio-content \
  rippleclio-web \
  wabifair-admin-console \
  wabifair-commerce \
  wabifair-storefront-web; do
  if [ ! -d "$ROOT_DIR/$repo/.git" ]; then
    echo "  Warning: $repo does not look like a git repository in $ROOT_DIR/$repo"
  fi
done

echo
echo "Setup complete. Suggested next steps:"
echo "  1. bash scripts/reset-and-build.sh"
echo "  2. bash scripts/start-frontends.sh"
