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
  component_path="components/$component"
  repo_files_path="$component_path/files"

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

  git -C "$repo_dir" -c core.quotePath=false ls-files -- "$repo_files_path" | LC_ALL=C sort > "$tmp_source"
  find "$target" -type f -print | LC_ALL=C sort > "$tmp_target"

  same=0
  local_behind=0
  repo_behind=0
  unknown=0
  missing_local=0
  local_only=0
  repo_dirty=0

  while IFS= read -r repo_path; do
    rel=${repo_path#"$repo_files_path"/}
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

    legacy_path="$component/$rel"
    match=$(find_history_match "$repo_path" "$legacy_path" "$target_blob" || true)

    if [ -z "$match" ]; then
      printf '? %s\n' "$rel"
      printf '    natural-location content matches no committed version\n'
      unknown=$((unknown + 1))
      continue
    fi

    if git -C "$repo_dir" merge-base --is-ancestor "$match" HEAD >/dev/null 2>&1; then
      changes=$(git -C "$repo_dir" rev-list --count "$match..HEAD" -- "$repo_path" "$legacy_path")
      printf '< %s\n' "$rel"
      printf '    natural location is behind repo by %s file-change commit(s)\n' "$changes"
      print_match_details "$match"
      local_behind=$((local_behind + 1))
      continue
    fi

    if git -C "$repo_dir" merge-base --is-ancestor HEAD "$match" >/dev/null 2>&1; then
      changes=$(git -C "$repo_dir" rev-list --count "HEAD..$match" -- "$repo_path" "$legacy_path")
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
    repo_path="$repo_files_path/$rel"
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

capture_tree() {
  component=$1
  source=$2
  target=$3
  component_path="components/$component"

  if [ -L "$target" ] || [ ! -d "$target" ]; then
    printf 'Cannot capture: expected a real directory at %s\n' "$target" >&2
    exit 1
  fi

  if [ -n "$(git -C "$repo_dir" status --porcelain -- "$component_path")" ]; then
    printf 'Refusing to capture over existing repo changes in %s/\n' "$component_path" >&2
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
  git -C "$repo_dir" status --short -- "$component_path"
  git -C "$repo_dir" diff -- "$component_path" || true
}
