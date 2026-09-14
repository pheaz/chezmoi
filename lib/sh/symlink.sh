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

    legacy_source="$repo_dir/$component"
    raw_target=$(readlink "$target" 2>/dev/null || true)
    if [ "$raw_target" = "$legacy_source" ]; then
      printf '! %s still points to legacy component path %s\n' "$target" "$legacy_source"
      printf '  Run: %s %s apply\n' "$0" "$component"
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

    legacy_source="$repo_dir/$component"
    raw_target=$(readlink "$target" 2>/dev/null || true)
    if [ "$raw_target" = "$legacy_source" ]; then
      rm "$target"
      ln -s "$source" "$target"
      printf 'Migrated %s from %s to %s\n' "$target" "$legacy_source" "$source"
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
