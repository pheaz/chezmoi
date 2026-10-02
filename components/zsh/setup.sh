#!/usr/bin/env sh
set -eu

action=$1
source=$2
target=$3
shared_config="$source/.zshrc"

[ -f "$shared_config" ] || {
  printf 'Missing zsh config: %s\n' "$shared_config" >&2
  exit 1
}

is_linked() {
  [ -L "$target" ] && [ "$target" -ef "$shared_config" ]
}

case "$action" in
  status)
    if is_linked; then
      printf '= %s -> %s\n' "$target" "$shared_config"
    elif [ -L "$target" ]; then
      printf '! %s is an unrelated or broken symlink; expected %s\n' "$target" "$shared_config" >&2
      exit 1
    elif [ -e "$target" ]; then
      if [ -f "$target" ] && cmp -s "$shared_config" "$target"; then
        printf '! %s matches the repo but is still a real file; back it up before applying.\n' "$target" >&2
      else
        printf '! %s exists and differs from the repo; review and back it up before applying.\n' "$target" >&2
      fi
      exit 1
    else
      printf '+ %s is missing; run zsh apply to link it.\n' "$target"
    fi
    ;;
  apply)
    if is_linked; then
      printf '%s is already linked to %s\n' "$target" "$shared_config"
      exit 0
    fi
    if [ -e "$target" ] || [ -L "$target" ]; then
      printf 'Refusing to replace existing %s; review and back it up before applying.\n' "$target" >&2
      exit 1
    fi
    mkdir -p "$(dirname -- "$target")"
    ln -s "$shared_config" "$target"
    printf 'Linked %s -> %s\n' "$target" "$shared_config"
    ;;
  *)
    printf 'Unsupported action: %s\n' "$action" >&2
    exit 2
    ;;
esac
