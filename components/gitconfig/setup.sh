#!/usr/bin/env sh
set -eu

action=$1
source=$2
target=$3
shared_config="$source/.gitconfig"

has_include() {
  git config --global --get-all include.path 2>/dev/null | grep -Fqx -- "$shared_config"
}

case "$action" in
  status)
    if has_include; then
      printf '= %s includes %s\n' "$target" "$shared_config"
      exit 0
    fi
    printf '! %s does not include %s\n' "$target" "$shared_config" >&2
    exit 1
    ;;
  apply)
    if has_include; then
      printf '%s already includes %s\n' "$target" "$shared_config"
      exit 0
    fi
    git config --global --add include.path "$shared_config"
    printf 'Added %s to global Git include.path\n' "$shared_config"
    ;;
  capture)
    printf 'capture is not supported for gitconfig; the machine-local %s is intentionally not tracked.\n' "$target" >&2
    exit 1
    ;;
  *)
    printf 'Unsupported action: %s\n' "$action" >&2
    exit 2
    ;;
esac
