#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
configs_dir="$repo_dir/configs"

. "$repo_dir/lib/sh/prerequisites.sh"
. "$repo_dir/lib/sh/manifests.sh"
. "$repo_dir/lib/sh/copy.sh"
. "$repo_dir/lib/sh/symlink.sh"

usage() {
  cat >&2 <<EOF
Usage:
  $0                         Configure all detected applications
  $0 <component> [status]
  $0 <component> apply
  $0 <component> capture

status    Inspect how the natural config relates to the repo.
apply     Configure the application according to the component mode.
capture   Import an existing real config directory into the repo working tree.
EOF
  exit 2
}

require_git_repo() {
  git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    printf 'Not a Git worktree: %s\n' "$repo_dir" >&2
    exit 1
  }
}

status_component() {
  case "$mode" in
    symlink) status_symlink "$component" "$source" "$target" ;;
    copy) status_tree "$component" "$source" "$target" ;;
  esac
}

apply_component() {
  case "$mode" in
    symlink) apply_symlink "$component" "$source" "$target" ;;
    copy) apply_tree "$component" "$source" "$target" ;;
  esac
}

capture_component() {
  if [ "$mode" = symlink ] && [ -L "$target" ]; then
    printf '%s is already a symlink into the repo; there is nothing to capture.\n' "$target"
    return 0
  fi

  capture_tree "$component" "$source" "$target"
}

auto_setup() {
  found=0

  for manifest in "$configs_dir"/*.yaml; do
    [ -e "$manifest" ] || continue
    found=1
    component=$(basename "$manifest" .yaml)
    load_component "$component"

    if [ -n "$detect_command" ] && ! command -v "$detect_command" >/dev/null 2>&1; then
      printf 'Skipping %s: %s not detected\n' "$component" "$detect_command"
      continue
    fi

    printf '\n== %s ==\n' "$component"
    if [ -e "$target" ] || [ -L "$target" ]; then
      status_component
    else
      apply_component
    fi
  done

  [ "$found" -eq 1 ] || printf 'No config manifests found in %s\n' "$configs_dir" >&2
}

require_git_repo
ensure_yq

if [ "$#" -eq 0 ]; then
  auto_setup
  exit 0
fi

component=$1
action=${2:-status}

[ "$#" -le 2 ] || usage
load_component "$component"

case "$action" in
  status) status_component ;;
  apply) apply_component ;;
  capture) capture_component ;;
  *) usage ;;
esac
