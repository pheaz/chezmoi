#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

usage() {
  cat >&2 <<EOF
Usage:
  $0 nvim [status]
  $0 nvim install
  $0 nvim materialize

status       Compare the live config with the repo without changing anything.
install      Copy the repo config into its natural location only if it is absent.
materialize  Replace an old symlink to the repo with a real directory copy.
EOF
  exit 2
}

require_git_repo() {
  git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    printf 'Not a Git worktree: %s\n' "$repo_dir" >&2
    exit 1
  }
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
    printf '! %s is a symlink, not an independent config copy\n' "$target"
    printf '  Run: %s %s materialize\n' "$0" "$component"
    return 1
  fi

  if [ ! -e "$target" ]; then
    printf '+ %s is missing locally\n' "$target"
    printf '  Run: %s %s install\n' "$0" "$component"
    return 0
  fi

  if [ ! -d "$target" ]; then
    printf '! Expected a directory at %s\n' "$target" >&2
    return 1
  fi

  tmp_source=$(mktemp)
  tmp_target=$(mktemp)
  trap 'rm -f "$tmp_source" "$tmp_target"' EXIT HUP INT TERM

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

  printf '\nSummary for %s\n' "$component"
  printf '  in sync:                  %s\n' "$same"
  printf '  natural location behind:  %s\n' "$local_behind"
  printf '  repo behind known version:%s\n' "$repo_behind"
  printf '  missing locally:           %s\n' "$missing_local"
  printf '  local-only files:          %s\n' "$local_only"
  printf '  unknown/divergent:         %s\n' "$unknown"

  if [ "$repo_dirty" -gt 0 ]; then
    printf '  repo files modified:       %s\n' "$repo_dirty"
  fi

  if [ "$unknown" -eq 0 ] && [ "$repo_behind" -eq 0 ] && [ "$local_only" -eq 0 ]; then
    if [ "$local_behind" -gt 0 ] || [ "$missing_local" -gt 0 ]; then
      printf '\nResult: natural location is behind the repo.\n'
    elif [ "$same" -gt 0 ]; then
      printf '\nResult: natural location and repo are in sync.\n'
    fi
  elif [ "$unknown" -eq 0 ] && [ "$local_behind" -eq 0 ] && [ "$missing_local" -eq 0 ] && [ "$repo_behind" -gt 0 ] && [ "$local_only" -eq 0 ]; then
    printf '\nResult: repo is behind a known natural-location version.\n'
  else
    printf '\nResult: the two copies have diverged or contain uncommitted/untracked differences.\n'
  fi
}

install_tree() {
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
  printf 'Installed %s -> %s\n' "$source" "$target"
}

materialize_tree() {
  component=$1
  source=$2
  target=$3

  if [ ! -L "$target" ]; then
    printf 'Refusing: %s is not a symlink. Nothing was changed.\n' "$target" >&2
    exit 1
  fi

  source_real=$(CDPATH= cd -- "$source" && pwd -P)
  target_real=$(CDPATH= cd -- "$target" 2>/dev/null && pwd -P || true)

  if [ "$source_real" != "$target_real" ]; then
    printf 'Refusing: %s does not point to this repo config. Nothing was changed.\n' "$target" >&2
    exit 1
  fi

  tmp="${target}.dotfiles-materialize.$$"
  rm -rf "$tmp"
  cp -R "$source" "$tmp"
  rm "$target"
  mv "$tmp" "$target"
  printf 'Materialized %s as an independent directory copy.\n' "$target"
  printf 'Run "%s %s status" to compare it with the repo.\n' "$0" "$component"
}

require_git_repo

component=${1:-}
action=${2:-status}

case "$component" in
  nvim)
    source="$repo_dir/nvim"
    target="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
    ;;
  *) usage ;;
esac

case "$action" in
  status) status_tree "$component" "$source" "$target" ;;
  install) install_tree "$component" "$source" "$target" ;;
  materialize) materialize_tree "$component" "$source" "$target" ;;
  *) usage ;;
esac
