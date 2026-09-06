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
