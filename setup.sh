#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
configs_dir="$repo_dir/configs"

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

require_yq() {
  command -v yq >/dev/null 2>&1 || {
    printf 'yq is required to read %s/*.yaml\n' "$configs_dir" >&2
    exit 1
  }
}

current_platform() {
  case "$(uname -s)" in
    Darwin) printf 'macos\n' ;;
    Linux) printf 'linux\n' ;;
    *) printf 'Unsupported platform: %s\n' "$(uname -s)" >&2; exit 1 ;;
  esac
}

expand_target() {
  value=$1

  case "$value" in
    '$HOME') printf '%s\n' "$HOME" ;;
    '$HOME/'*) printf '%s/%s\n' "$HOME" "${value#\$HOME/}" ;;
    '$XDG_CONFIG_HOME') printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}" ;;
    '$XDG_CONFIG_HOME/'*) printf '%s/%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}" "${value#\$XDG_CONFIG_HOME/}" ;;
    *) printf '%s\n' "$value" ;;
  esac
}

manifest_for() {
  printf '%s/%s.yaml\n' "$configs_dir" "$1"
}

load_component() {
  component=$1
  manifest=$(manifest_for "$component")

  [ -f "$manifest" ] || {
    printf 'Unknown component: %s\n' "$component" >&2
    exit 1
  }

  source="$repo_dir/$component"
  [ -d "$source" ] || {
    printf 'Missing repo config directory: %s\n' "$source" >&2
    exit 1
  }

  platform=$(current_platform)
  target_template=$(PLATFORM="$platform" yq -r '.target[strenv(PLATFORM)] // ""' "$manifest")
  [ -n "$target_template" ] || {
    printf 'Component %s has no target for %s\n' "$component" "$platform" >&2
    exit 1
  }

  target=$(expand_target "$target_template")
  detect_command=$(yq -r '.detect.command // ""' "$manifest")
  mode=$(yq -r '.mode // "copy"' "$manifest")

  case "$mode" in
    symlink|copy) ;;
    *) printf 'Unsupported mode for %s: %s\n' "$component" "$mode" >&2; exit 1 ;;
  esac
}

find_history_match() {
  repo_path=$1
  legacy_path=$2
  wanted_blob=$3

  for commit in $(git -C "$repo_dir" log --all --format='%H' -- "$repo_path" "$legacy_path"); do
    for candidate_path in "$repo_path" "$legacy_path"; do
      commit_blob=$(git -C "$repo_dir" rev-parse "$commit:$candidate_path" 2>/dev/null || true)
      if [ "$commit_blob" = "$wanted_blob" ]; then
        printf '%s\n' "$commit"
        return 0
      fi
    done
  done

  return 1
}

print_match_details() {
  commit=$1
  git -C "$repo_dir" show -s --format='    matches: %h %cs %s' "$commit"
}

status_tree() {
  component=$1
  source=$2
  target=$3

  if [ -L "$target" ]; then
    printf '! %s is a symlink; copy-mode comparison expects a real directory\n' "$target"
    return 1
  fi

  if [ ! -e "$target" ]; then
    printf '+ %s is missing locally\n' "$target"
    printf '  Run: %s %s apply\n' "$0" "$component"
    return 0
  fi

  if [ ! -d "$target" ]; then
    printf '! Expected a directory at %s\n' "$target" >&2
    return 1
  fi

  tmp_source=$(mktemp)
  tmp_target=$(mktemp)

  git -C "$repo_dir" -c core.quotePath=false ls-files -- "$component" | LC_ALL=C sort > "$tmp_source"
  find "$target" -type f -print | LC_ALL=C sort > "$tmp_target"

  same=0
  local_behind=0
  repo_behind=0
  unknown=0
  missing_local=0
  local_only=0
  repo_dirty=0

  while IFS= read -r repo_path; do
    rel=${repo_path#"$component"/}
    source_file="$repo_dir/$repo_path"
    target_file="$target/$rel"

    if [ ! -f "$source_file" ]; then
      printf '! %s\n' "$rel"
      printf '    tracked repo file is missing from the repo working copy\n'
      repo_dirty=$((repo_dirty + 1))
      unknown=$((unknown + 1))
      continue
    fi

    if [ ! -e "$target_file" ]; then
      printf '+ %s\n' "$rel"
      printf '    missing from natural location\n'
      missing_local=$((missing_local + 1))
      continue
    fi

    if [ ! -f "$target_file" ]; then
      printf '! %s\n' "$rel"
      printf '    natural-location entry is not a regular file\n'
      unknown=$((unknown + 1))
      continue
    fi

    source_blob=$(git -C "$repo_dir" hash-object "$source_file")
    target_blob=$(git -C "$repo_dir" hash-object "$target_file")

    if [ "$source_blob" = "$target_blob" ]; then
      printf '= %s\n' "$rel"
      same=$((same + 1))
      continue
    fi

    head_blob=$(git -C "$repo_dir" rev-parse "HEAD:$repo_path" 2>/dev/null || true)

    if [ -z "$head_blob" ]; then
      printf '? %s\n' "$rel"
      printf '    repo copy is not present in HEAD; ordering is unknown\n'
      unknown=$((unknown + 1))
      continue
    fi

    if [ "$source_blob" != "$head_blob" ]; then
      printf '? %s\n' "$rel"
      printf '    repo working copy has uncommitted content; ordering is unknown\n'
      repo_dirty=$((repo_dirty + 1))
      unknown=$((unknown + 1))
      continue
    fi

    match=$(find_history_match "$repo_path" "$rel" "$target_blob" || true)

    if [ -z "$match" ]; then
      printf '? %s\n' "$rel"
      printf '    natural-location content matches no committed version\n'
      unknown=$((unknown + 1))
      continue
    fi

    if git -C "$repo_dir" merge-base --is-ancestor "$match" HEAD >/dev/null 2>&1; then
      changes=$(git -C "$repo_dir" rev-list --count "$match..HEAD" -- "$repo_path")
      printf '< %s\n' "$rel"
      printf '    natural location is behind repo by %s file-change commit(s)\n' "$changes"
      print_match_details "$match"
      local_behind=$((local_behind + 1))
      continue
    fi

    if git -C "$repo_dir" merge-base --is-ancestor HEAD "$match" >/dev/null 2>&1; then
      changes=$(git -C "$repo_dir" rev-list --count "HEAD..$match" -- "$repo_path")
      printf '> %s\n' "$rel"
      printf '    repo HEAD is behind this known natural-location version by %s file-change commit(s)\n' "$changes"
      print_match_details "$match"
      repo_behind=$((repo_behind + 1))
      continue
    fi

    printf '~ %s\n' "$rel"
    printf '    natural location matches Git history, but on a divergent history\n'
    print_match_details "$match"
    unknown=$((unknown + 1))
  done < "$tmp_source"

  while IFS= read -r target_file; do
    rel=${target_file#"$target"/}
    repo_path="$component/$rel"
    if git -C "$repo_dir" ls-files --error-unmatch -- "$repo_path" >/dev/null 2>&1; then
      continue
    fi
    if git -C "$repo_dir" check-ignore -q -- "$repo_path" 2>/dev/null; then
      continue
    fi
    printf '> %s\n' "$rel"
    printf '    exists only in natural location\n'
    local_only=$((local_only + 1))
  done < "$tmp_target"

  rm -f "$tmp_source" "$tmp_target"

  printf '\nSummary for %s\n' "$component"
  printf '  in sync:                   %s\n' "$same"
  printf '  natural location behind:   %s\n' "$local_behind"
  printf '  repo behind known version: %s\n' "$repo_behind"
  printf '  missing locally:            %s\n' "$missing_local"
  printf '  local-only files:           %s\n' "$local_only"
  printf '  unknown/divergent:          %s\n' "$unknown"

  if [ "$repo_dirty" -gt 0 ]; then
    printf '  repo files modified:        %s\n' "$repo_dirty"
  fi
}

link_destination() {
  target=$1

  if [ ! -L "$target" ]; then
    return 1
  fi

  if [ -d "$target" ]; then
    CDPATH= cd -- "$target" 2>/dev/null && pwd -P
    return
  fi

  return 1
}

status_symlink() {
  component=$1
  source=$2
  target=$3

  if [ -L "$target" ]; then
    expected=$(CDPATH= cd -- "$source" && pwd -P)
    actual=$(link_destination "$target" || true)

    if [ "$actual" = "$expected" ]; then
      printf '= %s -> %s\n' "$target" "$source"
      return 0
    fi

    if [ -z "$actual" ]; then
      printf '! %s is a broken symlink\n' "$target" >&2
    else
      printf '! %s points to %s, expected %s\n' "$target" "$actual" "$expected" >&2
    fi
    return 1
  fi

  if [ -e "$target" ]; then
    if [ -d "$target" ]; then
      printf '! %s is a real directory; expected a symlink to %s\n' "$target" "$source"
      printf '  Comparing the existing directory before migration:\n\n'
      status_tree "$component" "$source" "$target"
      return
    fi

    printf '! %s exists but is not a directory symlink\n' "$target" >&2
    return 1
  fi

  printf '+ %s is missing\n' "$target"
  printf '  Run: %s %s apply\n' "$0" "$component"
}

apply_tree() {
  component=$1
  source=$2
  target=$3

  if [ -e "$target" ] || [ -L "$target" ]; then
    printf 'Refusing to replace existing %s\n' "$target" >&2
    printf 'Run "%s %s status" to compare it first.\n' "$0" "$component" >&2
    exit 1
  fi

  mkdir -p "$(dirname -- "$target")"
  cp -R "$source" "$target"
  printf 'Applied %s -> %s\n' "$source" "$target"
}

apply_symlink() {
  component=$1
  source=$2
  target=$3

  if [ -L "$target" ]; then
    expected=$(CDPATH= cd -- "$source" && pwd -P)
    actual=$(link_destination "$target" || true)
    if [ "$actual" = "$expected" ]; then
      printf '%s is already linked to %s\n' "$target" "$source"
      return 0
    fi
    printf 'Refusing to replace existing symlink %s\n' "$target" >&2
    exit 1
  fi

  if [ -e "$target" ]; then
    printf 'Refusing to replace existing %s\n' "$target" >&2
    printf 'Run "%s %s status" first; capture it if needed, then move/remove it before applying.\n' "$0" "$component" >&2
    exit 1
  fi

  mkdir -p "$(dirname -- "$target")"
  ln -s "$source" "$target"
  printf 'Linked %s -> %s\n' "$target" "$source"
}

capture_tree() {
  component=$1
  source=$2
  target=$3

  if [ -L "$target" ] || [ ! -d "$target" ]; then
    printf 'Cannot capture: expected a real directory at %s\n' "$target" >&2
    exit 1
  fi

  if [ -n "$(git -C "$repo_dir" status --porcelain -- "$component")" ]; then
    printf 'Refusing to capture over existing repo changes in %s/\n' "$component" >&2
    printf 'Commit, discard, or move those changes first.\n' >&2
    exit 1
  fi

  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT HUP INT TERM
  cp -R "$target"/. "$tmp"/

  rm -rf "$source"
  mkdir -p "$source"
  cp -R "$tmp"/. "$source"/

  printf 'Captured %s -> %s\n\n' "$target" "$source"
  git -C "$repo_dir" status --short -- "$component"
  git -C "$repo_dir" diff -- "$component" || true
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
require_yq

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
