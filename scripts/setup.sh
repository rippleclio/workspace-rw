#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REMOTE_BASE="${SETUP_REMOTE_BASE:-https://github.com/rippleclio}"

REPOS=(
  core-platform
  documents
  rippleclio-admin-console
  rippleclio-content
  rippleclio-web
  wabifair-admin-console
  wabifair-commerce
  wabifair-storefront-web
)

TARGET_REPOS=()

is_known_repo() {
  local repo="$1"
  for known in "${REPOS[@]}"; do
    if [ "$known" = "$repo" ]; then
      return 0
    fi
  done
  return 1
}

echo "============================================"
echo "  Workspace repository clone setup"
echo "============================================"
echo

if ! command -v git > /dev/null 2>&1; then
  echo "git is required but was not found in PATH."
  exit 1
fi

if [ "$#" -gt 0 ]; then
  for repo in "$@"; do
    if ! is_known_repo "$repo"; then
      echo "Unknown repository: $repo"
      echo "Allowed values: ${REPOS[*]}"
      exit 1
    fi
    TARGET_REPOS+=("$repo")
  done
else
  TARGET_REPOS=("${REPOS[@]}")
fi

step=0
total="${#TARGET_REPOS[@]}"
REMOTE_BASE="${REMOTE_BASE%/}"

for repo in "${TARGET_REPOS[@]}"; do
  step=$((step + 1))
  target_dir="$ROOT_DIR/$repo"
  clone_url="$REMOTE_BASE/$repo.git"

  echo "[$step/$total] $repo"

  if [ -d "$target_dir/.git" ]; then
    echo "  Skip: repository already exists at $target_dir"
    echo
    continue
  fi

  if [ -e "$target_dir" ]; then
    echo "  Skip: target path already exists but is not a git repository: $target_dir"
    echo
    continue
  fi

  echo "  Clone: $clone_url"
  git clone "$clone_url" "$target_dir"
  echo
done

echo
echo "Setup complete. Suggested next steps:"
echo "  1. bash scripts/install-frontends.sh"
echo "  2. bash scripts/reset-and-build.sh"
echo "  3. bash scripts/start-frontends.sh"
echo
echo "Tips:"
echo "  - Default clone source: $REMOTE_BASE/<repo>.git"
echo "  - Override with SETUP_REMOTE_BASE, for example:"
echo "      SETUP_REMOTE_BASE=git@github.com:rippleclio bash scripts/setup.sh"
