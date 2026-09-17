#!/usr/bin/env sh
set -eu

action=$1
source=$2
target=$3
settings="$source/defaults.yaml"

setting_keys() {
  yq -r '.global | keys | .[]' "$settings"
}

setting_type() {
  KEY="$1" yq -r '.global[strenv(KEY)].type' "$settings"
}

expected_value() {
  expected_key=$1
  expected_type=$2

  case "$expected_type" in
    array)
      KEY="$expected_key" yq -o=json -I=0 '.global[strenv(KEY)].value' "$settings"
      ;;
    bool|string|int|float)
      KEY="$expected_key" yq -r '.global[strenv(KEY)].value' "$settings"
      ;;
    *)
      printf 'Unsupported macOS default type for %s: %s\n' "$expected_key" "$expected_type" >&2
      exit 1
      ;;
  esac
}

current_value() {
  current_key=$1
  current_type=$2
  current_raw=$(defaults read -g "$current_key" 2>/dev/null || true)

  [ -n "$current_raw" ] || return 0

  case "$current_type" in
    bool)
      case "$current_raw" in
        1|true) printf 'true\n' ;;
        0|false) printf 'false\n' ;;
        *) printf '%s\n' "$current_raw" ;;
      esac
      ;;
    array)
      printf '%s\n' "$current_raw" \
        | plutil -convert json -o - - 2>/dev/null \
        | yq -p=json -o=json -I=0 '.' 2>/dev/null \
        || true
      ;;
    string|int|float)
      printf '%s\n' "$current_raw"
      ;;
    *)
      printf 'Unsupported macOS default type for %s: %s\n' "$current_key" "$current_type" >&2
      exit 1
      ;;
  esac
}

write_setting() {
  write_key=$1
  write_type=$2
  write_expected=$3

  case "$write_type" in
    bool)
      defaults write -g "$write_key" -bool "$write_expected"
      ;;
    string)
      defaults write -g "$write_key" -string "$write_expected"
      ;;
    int)
      defaults write -g "$write_key" -int "$write_expected"
      ;;
    float)
      defaults write -g "$write_key" -float "$write_expected"
      ;;
    array)
      array_values=$(KEY="$write_key" yq -r '.global[strenv(KEY)].value[]' "$settings")
      old_ifs=$IFS
      IFS=$(printf '\nX')
      IFS=${IFS%X}
      set -f
      # Split only on newlines so array elements may contain spaces.
      # shellcheck disable=SC2086
      set -- $array_values
      set +f
      IFS=$old_ifs
      defaults write -g "$write_key" -array "$@"
      ;;
    *)
      printf 'Unsupported macOS default type for %s: %s\n' "$write_key" "$write_type" >&2
      exit 1
      ;;
  esac
}

status_settings() {
  status=0

  for setting_key in $(setting_keys); do
    type=$(setting_type "$setting_key")
    expected=$(expected_value "$setting_key" "$type")
    current=$(current_value "$setting_key" "$type")

    if [ "$current" = "$expected" ]; then
      printf '= %s: %s=%s\n' "$target" "$setting_key" "$expected"
    else
      printf '! %s: %s is %s, expected %s\n' \
        "$target" "$setting_key" "${current:-unset}" "$expected" >&2
      status=1
    fi
  done

  return "$status"
}

apply_settings() {
  for setting_key in $(setting_keys); do
    type=$(setting_type "$setting_key")
    expected=$(expected_value "$setting_key" "$type")
    current=$(current_value "$setting_key" "$type")

    if [ "$current" = "$expected" ]; then
      printf '%s already has %s=%s\n' "$target" "$setting_key" "$expected"
      continue
    fi

    write_setting "$setting_key" "$type" "$expected"
    printf 'Set global macOS default %s=%s\n' "$setting_key" "$expected"
  done
}

case "$action" in
  status)
    status_settings
    ;;
  apply)
    apply_settings
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
