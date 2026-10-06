# ADR 0001: Manage dotfiles with chezmoi

Status: Accepted. Supersedes the former component-engine ADRs; those remain in Git history.

The repository root is the chezmoi source-state root. The normal checkout is
~/.local/share/chezmoi. Symlink mode links eligible regular files to source files;
directories remain directories. Templates and explicit symlink targets follow
chezmoi's normal behavior.

One Neovim tree serves all systems. Default POSIX paths use source-state files.
Windows uses a conditional directory symlink. A native run script handles a
redirected LOCALAPPDATA or nondefault XDG_CONFIG_HOME, including paths outside HOME.
Karabiner and macOS defaults apply only on macOS; zsh applies on macOS and Linux.

Portable Git settings are an included file. An idempotent native after script
registers that include without managing the entire machine-local ~/.gitconfig.
Fixed macOS preferences use a native run_onchange script without yq.

Repository documentation, automation, and the editor workspace are ignored by
chezmoi. The former setup scripts, manifests, and orchestration libraries are removed.

The Neovim and Karabiner directory layout described above is superseded by
ADR 0002. These applications now use explicit directory symlinks.
