#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

link_nvim() {
  target="$HOME/.config/nvim"
  source="$repo_dir/nvim"

  mkdir -p "$HOME/.config"

  if [ -e "$target" ] || [ -L "$target" ]; then
    printf 'Refusing to replace existing %s\n' "$target" >&2
    exit 1
  fi

  ln -s "$source" "$target"
  printf 'Linked %s -> %s\n' "$target" "$source"
}

case "${1:-}" in
  nvim) link_nvim ;;
  *)
    printf 'Usage: %s nvim\n' "$0" >&2
    exit 2
    ;;
esac
