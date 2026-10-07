# ADR 0003: Group application configuration payloads

Status: Accepted. Supersedes ADR 0002's layout for zsh and portable Git settings.

Keep zsh and portable Git configuration alongside Neovim and Karabiner under
configs/. Explicit native chezmoi symlink templates retain the destinations
~/.zshrc and ~/.config/git/portable.inc. The existing Git include registration
and platform exclusions continue to apply.

This deliberately favors application grouping over chezmoi's conventional
destination-based payload layout. Chezmoi still owns deployment through native
symlink templates and run scripts; no component manifests or orchestration are
introduced. macOS defaults remain in their existing run_onchange script.
