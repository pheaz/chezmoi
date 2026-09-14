#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
components_dir="$repo_dir/components"

. "$repo_dir/lib/sh/prerequisites.sh"
. "$repo_dir/lib/sh/manifests.sh"
. "$repo_dir/lib/sh/copy.sh"
. "$repo_dir/lib/sh/symlink.sh"

usage() {
  cat >&2 <<EOF
Usage:
  $0                         Configure all detected components
  $0 <component> [status]
  $0 <component> apply
  $0 <component> capture

status    Inspect how the natural config relates to the repo.
apply     Configure the component according to its installation mode.
capture   Import an existing real config directory into the repo files tree.
EOF
  exit 2
}

require_git_repo() {
  git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    printf 'Not a Git worktree: %s\n' "$repo_dir" >&2
    exit 1
  }
}

run_component_setup() {
  action=$1
  require_component_setup_script
  sh "$setup_script" "$action" "$source" "$target"
}

status_component() {
  case "$mode" in
    symlink) status_symlink "$component" "$source" "$target" ;;
    copy) status_tree "$component" "$source" "$target" ;;
    setup) run_component_setup status ;;
  esac
}

apply_component() {
  case "$mode" in
    symlink) apply_symlink "$component" "$source" "$target" ;;
    copy) apply_tree "$component" "$source" "$target" ;;
    setup) run_component_setup apply ;;
  esac
}

capture_component() {
  if [ "$mode" = setup ]; then
    printf 'capture is not supported for setup-mode component %s\n' "$component" >&2
    return 1
  fi

  if [ "$mode" = symlink ] && [ -L "$target" ]; then
    printf '%s is already a symlink into the repo; there is nothing to capture.\n' "$target"
    return 0
  fi

  capture_tree "$component" "$source" "$target"
}

auto_setup() {
  found=0

  for component_dir in "$components_dir"/*; do
    [ -d "$component_dir" ] || continue
    [ -f "$component_dir/manifest.yaml" ] || continue
    found=1
    component=$(basename "$component_dir")
    load_component "$component"

    if [ -z "$target" ]; then
      printf 'Skipping %s: no target for %s\n' "$component" "$platform"
      continue
    fi

    if [ -n "$detect_command" ] && ! command -v "$detect_command" >/dev/null 2>&1; then
      printf 'Skipping %s: %s not detected\n' "$component" "$detect_command"
      continue
    fi

    if [ ! -d "$source" ]; then
      if [ "$mode" != setup ] && [ -d "$target" ] && [ ! -L "$target" ]; then
        printf 'Skipping %s: component files have not been captured yet\n' "$component"
        printf '  Run: %s %s capture\n' "$0" "$component"
      else
        printf 'Skipping %s: missing component files directory %s\n' "$component" "$source"
      fi
      continue
    fi

    printf '\n== %s ==\n' "$component"
    if [ "$mode" = setup ]; then
      apply_component
    elif [ -e "$target" ] || [ -L "$target" ]; then
      status_component
    else
      apply_component
    fi
  done

  [ "$found" -eq 1 ] || printf 'No component manifests found in %s\n' "$components_dir" >&2
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
require_component_target
require_component_source

case "$action" in
  status) status_component ;;
  apply) apply_component ;;
  capture) capture_component ;;
  *) usage ;;
esac
