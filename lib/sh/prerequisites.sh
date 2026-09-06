ensure_yq() {
  if command -v yq >/dev/null 2>&1; then
    return
  fi

  install_dir="$HOME/.local/bin"
  local_yq="$install_dir/yq"

  if [ -x "$local_yq" ]; then
    PATH="$install_dir:$PATH"
    export PATH
    return
  fi

  case "$(uname -s)" in
    Darwin) yq_os=darwin ;;
    Linux) yq_os=linux ;;
    *)
      printf 'Cannot bootstrap yq on unsupported platform: %s\n' "$(uname -s)" >&2
      exit 1
      ;;
  esac

  case "$(uname -m)" in
    x86_64|amd64) yq_arch=amd64 ;;
    arm64|aarch64) yq_arch=arm64 ;;
    *)
      printf 'Cannot bootstrap yq on unsupported architecture: %s\n' "$(uname -m)" >&2
      exit 1
      ;;
  esac

  mkdir -p "$install_dir"
  tmp=$(mktemp)
  url="https://github.com/mikefarah/yq/releases/latest/download/yq_${yq_os}_${yq_arch}"

  printf 'Installing yq to %s\n' "$local_yq"
  if command -v curl >/dev/null 2>&1; then
    if ! curl -fsSL "$url" -o "$tmp"; then
      rm -f "$tmp"
      printf 'Failed to download yq from %s\n' "$url" >&2
      exit 1
    fi
  elif command -v wget >/dev/null 2>&1; then
    if ! wget -qO "$tmp" "$url"; then
      rm -f "$tmp"
      printf 'Failed to download yq from %s\n' "$url" >&2
      exit 1
    fi
  else
    rm -f "$tmp"
    printf 'curl or wget is required to bootstrap yq.\n' >&2
    exit 1
  fi

  chmod +x "$tmp"
  mv "$tmp" "$local_yq"
  PATH="$install_dir:$PATH"
  export PATH
}
