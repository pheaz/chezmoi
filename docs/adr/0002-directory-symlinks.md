# ADR 0002: Explicit directory symlinks for application configurations

Status: Accepted. Supersedes ADR 0001's per-file Neovim and Karabiner layout.
Implementation: chezmoi-directory-symlinks-v1

Keep one tracked raw tree per application under configs/. Ignore that directory
in chezmoi and use symlink_ templates pointing into it. Ordinary symlink mode
continues to manage zsh and portable Git settings as before.

Neovim uses XDG_CONFIG_HOME/nvim on macOS/Linux, with ~/.config as the fallback,
and LOCALAPPDATA/nvim on Windows. Native after scripts handle redirected paths
outside the normal HOME source-state mapping without duplicating configuration.
Karabiner uses ~/.config/karabiner on macOS only. Its directory must be linked
rather than karabiner.json so that configuration changes reload automatically.

Directory symlinks expose application-created files directly in the checkout.
Generated files remain ignored; review git status before committing. Local-only
extras preserved by the migration are excluded through .git/info/exclude.
