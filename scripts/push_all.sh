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
  echo "Usage: bash scripts/push_all.sh [repo ...]"
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
echo "  Push repositories"
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

  if [ -n "$(git -C "$repo_dir" status --short)" ]; then
    echo "  Skip: working tree is not clean"
    echo
    continue
  fi

  branch_name="$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD)"
  if [ "$branch_name" = "HEAD" ]; then
    echo "  Skip: detached HEAD"
    echo
    continue
  fi

  if ! git -C "$repo_dir" remote get-url origin > /dev/null 2>&1; then
    echo "  Skip: remote origin not configured"
    echo
    continue
  fi

  git -C "$repo_dir" fetch origin "$branch_name" --quiet > /dev/null 2>&1 || true

  if git -C "$repo_dir" rev-parse --abbrev-ref --symbolic-full-name '@{u}' > /dev/null 2>&1; then
    local_ref="$(git -C "$repo_dir" rev-parse @)"
    upstream_ref="$(git -C "$repo_dir" rev-parse '@{u}')"
    base_ref="$(git -C "$repo_dir" merge-base @ '@{u}')"

    if [ "$local_ref" = "$upstream_ref" ]; then
      echo "  Nothing to push"
      echo
      continue
    fi

    if [ "$upstream_ref" = "$base_ref" ]; then
      git -C "$repo_dir" push
      echo "  Pushed branch: $branch_name"
      echo
      continue
    fi

    if [ "$local_ref" = "$base_ref" ]; then
      echo "  Skip: remote branch is ahead, pull first"
      echo
      continue
    fi

    echo "  Skip: local and upstream have diverged"
    echo
    continue
  fi

  git -C "$repo_dir" push -u origin "$branch_name"
  echo "  Pushed and set upstream: $branch_name"
  echo
done
