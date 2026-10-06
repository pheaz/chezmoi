eval "$(/opt/homebrew/bin/brew shellenv)"
setopt interactivecomments
export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
export PATH="$HOME/.local/bin:$PATH"

bindkey '^P' up-history
bindkey '^N' down-history

autoload -Uz compinit
compinit -D

zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'm:{a-zA-Z}={A-Za-z} r:|[._-]=* r:|=*'
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
