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

TARGET_REPOS=()

print_available_repos() {
  echo "Available repositories:"
  for entry in "${REPOS[@]}"; do
    echo "  - ${entry%%:*}"
  done
}

usage() {
  echo "Usage: bash scripts/commit_all.sh \"commit message\" [repo ...]"
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

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
  exit 0
fi

COMMIT_MESSAGE="$1"
shift
TARGET_REPOS=("$@")
validate_targets "${TARGET_REPOS[@]}"

TOTAL="$(selected_total)"
STEP=0
CHANGED_REPOS=0
COMMITTED_REPOS=0

echo "============================================"
echo "  Commit repositories"
echo "============================================"
echo "Commit message: $COMMIT_MESSAGE"
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

  if [ -z "$(git -C "$repo_dir" status --short)" ]; then
    echo "  No changes"
    echo
    continue
  fi

  CHANGED_REPOS=$((CHANGED_REPOS + 1))
  branch_name="$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD)"

  git -C "$repo_dir" add -A

  if [ -z "$(git -C "$repo_dir" diff --cached --name-only)" ]; then
    echo "  Skip: nothing staged after git add -A"
    echo
    continue
  fi

  git -C "$repo_dir" commit -m "$COMMIT_MESSAGE"
  COMMITTED_REPOS=$((COMMITTED_REPOS + 1))

  echo "  Committed on branch: $branch_name"
  echo
done

echo "Selected repositories:  $TOTAL"
echo "Changed repositories:   $CHANGED_REPOS"
echo "Committed repositories: $COMMITTED_REPOS"
