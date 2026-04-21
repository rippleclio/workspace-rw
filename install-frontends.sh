#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "============================================"
echo "  Installing frontend npm dependencies"
echo "============================================"
echo

install_repo() {
  local step="$1"
  local total="$2"
  local repo="$3"

  echo "[$step/$total] $repo"
  (
    cd "$SCRIPT_DIR/$repo"
    npm install
  )
  echo
}

install_repo 1 4 wabifair-storefront-web
install_repo 2 4 wabifair-admin-console
install_repo 3 4 rippleclio-admin-console
install_repo 4 4 rippleclio-web

echo "All frontend npm dependencies installed successfully."