#!/usr/bin/env sh
set -eu

action=$1
source=$2
target=$3
settings="$source/defaults.yaml"
key=ApplePressAndHoldEnabled
expected=$(yq -r ".global.$key.value" "$settings")

case "$expected" in
  true) expected_numeric=1 ;;
  false) expected_numeric=0 ;;
  *)
    printf 'Unsupported boolean value for %s: %s\n' "$key" "$expected" >&2
    exit 1
    ;;
esac

current_value() {
  defaults read -g "$key" 2>/dev/null || true
}

case "$action" in
  status)
    current=$(current_value)
    if [ "$current" = "$expected_numeric" ]; then
      printf '= %s: %s=%s\n' "$target" "$key" "$expected"
      exit 0
    fi
    printf '! %s: %s is %s, expected %s\n' "$target" "$key" "${current:-unset}" "$expected" >&2
    exit 1
    ;;
  apply)
    current=$(current_value)
    if [ "$current" = "$expected_numeric" ]; then
      printf '%s already has %s=%s\n' "$target" "$key" "$expected"
      exit 0
    fi
    defaults write -g "$key" -bool "$expected"
    printf 'Set global macOS default %s=%s\n' "$key" "$expected"
    ;;
  capture)
    printf 'capture is not supported for macos-defaults.\n' >&2
    exit 1
    ;;
  *)
    printf 'Unsupported action: %s\n' "$action" >&2
    exit 2
    ;;
esac
