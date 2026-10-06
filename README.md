# chezmoi

Private configuration managed by chezmoi. The repository root is the source-state
root, the normal checkout is ~/.local/share/chezmoi, and no .chezmoiroot is needed.
The local configuration template sets mode = "symlink".

## Installation and daily use

Install Git and chezmoi, authenticate for this private repository, then run:

```sh
chezmoi init --apply pheaz/chezmoi
```

Use chezmoi update to fetch and apply changes, chezmoi diff to review them,
and chezmoi apply to apply local source changes. chezmoi cd opens a shell in
this checkout. The normal Git workflow is:

```sh
chezmoi cd
git add .
git commit -m "..."
git push
```

Use a feature branch and pull request for changes to protected main.

## Source-state layout

- configs/nvim/: the single tracked raw Neovim tree for all platforms.
- configs/karabiner/: the tracked raw Karabiner tree.
- dot_config/symlink_nvim.tmpl: the default POSIX Neovim directory link.
- dot_config/symlink_karabiner.tmpl: the macOS Karabiner directory link.
- AppData/Local/symlink_nvim.tmpl: the standard Windows Neovim directory link.
- dot_config/git/portable.inc: portable Git settings.
- dot_zshrc: the macOS/Linux ~/.zshrc.
- run_after_10-nvim-*: redirected XDG/Windows path support.
- run_after_20-git-include.*: idempotent portable Git include registration.
- run_onchange_after_30-macos-defaults.sh.tmpl: fixed macOS preferences, without yq.
- .chezmoi.toml.tmpl and .chezmoiignore: local configuration and target exclusions.
- README.md, docs/, .github/, .githooks/, and chezmoi.code-workspace: repository metadata.

configs/ is ignored by chezmoi. Explicit symlink templates expose each application
as one directory link; its children remain ordinary files in the tracked tree.
Ordinary symlink mode still links eligible other files, including ~/.zshrc.

## Platform paths and local files

Neovim uses $XDG_CONFIG_HOME/nvim on macOS/Linux, falling back to ~/.config/nvim.
Windows uses $LOCALAPPDATA/nvim. Redirected absolute paths use native after scripts
pointing at the same configs/nvim tree. Enable Windows Developer Mode or provide
symlink creation permission. Existing unrelated destinations are refused.

Karabiner uses ~/.config/karabiner on macOS only. Link the directory, not just
karabiner.json, so Karabiner can detect configuration changes. Restart Karabiner
after first changing the directory link. zsh is ignored on Windows.

Portable Git settings are included once from ~/.config/git/portable.inc by the
machine-local ~/.gitconfig. Credential helpers and other local settings remain
there; do not add the entire machine-local file to chezmoi.

Edits through either application directory change its source files directly.
New files appear in git status unless ignored. Karabiner backups and generated
Neovim cache files are ignored. The migration preserves other local-only extras
and excludes those specific untracked files through .git/info/exclude; use git add -f on
specific intended files to start tracking them. Never force-add the whole tree.

## Migration history

The pre-chezmoi-migration tag preserves the former component framework.
The pre-directory-symlinks tag preserves the earlier per-file application layout.
ADRs in docs/adr/ record both decisions. Local directory migration backups live
under .git/chezmoi-directory-link-backup.*. An unrelated ~/karabiner is left alone.

## Repository-managed Git hooks

On macOS/Linux, `.githooks/post-merge` and `.githooks/post-rewrite` automatically
run `chezmoi apply` after successful merges and rebases. An already up-to-date
pull does not trigger them. Calls from `chezmoi update` skip duplicate application;
manual Git commands inside `chezmoi cd` remain supported.

`run_onchange_after_40-git-hooks.sh.tmpl` installs these tracked hooks into
`.git/hooks` during `chezmoi init --apply` and reruns when their contents change.
Unrelated existing hooks and custom `core.hooksPath` settings require integration.
Replaced versions of these hooks are preserved under `.git/chezmoi-hook-backup.*`.
The hook installer is inactive on Windows. Hook installation does not alter the
existing Windows configuration targets.

`main` requires a pull request. Commit and push changes on a feature branch,
merge the PR, then use `chezmoi update` on main.
