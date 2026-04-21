#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

REPOS=(
  "workspace-rw:."
  "core-platform:core-platform"
  "documents:documents"
  "rippleclio-admin-console:rippleclio-admin-console"
  "rippleclio-content:rippleclio-content"
  "rippleclio-web:rippleclio-web"
  "wabifair-admin-console:wabifair-admin-console"
  "wabifair-commerce:wabifair-commerce"
  "wabifair-storefront-web:wabifair-storefront-web"
)

TARGET_REPOS=("$@")

print_available_repos() {
  echo "Available repositories:"
  for entry in "${REPOS[@]}"; do
    echo "  - ${entry%%:*}"
  done
}

usage() {
  echo "Usage: bash scripts/status_all.sh [repo ...]"
  print_available_repos
}

is_selected() {
  local repo_name="$1"

  if [ "${#TARGET_REPOS[@]}" -eq 0 ]; then
    return 0
  fi

  for target in "${TARGET_REPOS[@]}"; do
    if [ "$target" = "$repo_name" ]; then
      return 0
    fi
  done

  return 1
}

validate_targets() {
  local target
  local entry

  for target in "$@"; do
    for entry in "${REPOS[@]}"; do
      if [ "$target" = "${entry%%:*}" ]; then
        continue 2
      fi
    done

    echo "Unknown repository: $target" >&2
    print_available_repos >&2
    exit 1
  done
}

selected_total() {
  local count=0
  local entry

  for entry in "${REPOS[@]}"; do
    if is_selected "${entry%%:*}"; then
      count=$((count + 1))
    fi
  done

  echo "$count"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

validate_targets "${TARGET_REPOS[@]}"

TOTAL="$(selected_total)"
STEP=0

echo "============================================"
echo "  Repository status"
echo "============================================"
echo

for entry in "${REPOS[@]}"; do
  name="${entry%%:*}"
  relative_path="${entry#*:}"

  if ! is_selected "$name"; then
    continue
  fi

  STEP=$((STEP + 1))
  repo_dir="$ROOT_DIR/$relative_path"

  echo "[$STEP/$TOTAL] $name"

  if [ ! -d "$repo_dir" ]; then
    echo "  Skip: directory not found -> $repo_dir"
    echo
    continue
  fi

  if ! git -C "$repo_dir" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "  Skip: not a git repository"
    echo
    continue
  fi

  status_output="$(git -C "$repo_dir" status --short --branch 2>/dev/null || true)"
  if [ -z "$status_output" ]; then
    echo "  Clean"
    echo
    continue
  fi

  while IFS= read -r line; do
    echo "  $line"
  done <<< "$status_output"
  echo
done