# chezmoi

Private, cross-platform configuration managed by [chezmoi](https://www.chezmoi.io/).
The repository root is the source-state root; the normal checkout lives at
`~/.local/share/chezmoi`. No `.chezmoiroot` is needed.

## Installation and daily use

Install chezmoi and Git and authenticate for this private GitHub repository, then:

```sh
chezmoi init --apply pheaz/chezmoi
```

Use `chezmoi init --apply --ssh pheaz/chezmoi` to clone with SSH instead of HTTPS.
Fetch and apply upstream changes with `chezmoi update`. Use `chezmoi diff` or
`chezmoi apply --dry-run --verbose` to inspect changes, and `chezmoi apply` to apply them.
Run `chezmoi init` after changing the configuration template.

Normal Git workflow:

```sh
chezmoi cd
git add .
git commit -m "..."
git push
```

`chezmoi cd` opens a shell in the source directory. Close that nested shell when done.

## Source-state layout

- `dot_config/nvim/`: the single tracked Neovim configuration tree.
- `dot_config/karabiner/`: macOS-only Karabiner configuration.
- `dot_config/git/portable.inc`: portable Git settings.
- `dot_zshrc`: macOS/Linux `~/.zshrc`.
- `AppData/Local/symlink_nvim.tmpl`: the usual Windows Neovim directory symlink.
- `run_after_10-nvim-*`: idempotent native scripts for redirected configuration paths.
- `run_after_20-git-include.*`: idempotent native Git include registration.
- `run_onchange_after_30-macos-defaults.sh.tmpl`: fixed global macOS preferences.
- `.chezmoi.toml.tmpl`: generated local configuration with `mode = "symlink"`.
- `.chezmoiignore`: platform exclusions and repository-only files.
- `docs/`, `.github/`, `README.md`, and `chezmoi.code-workspace`: repository metadata.

Symlink mode links eligible regular files to the checkout. It does not turn every
directory into a symlink, and templates, private files, and executable files have
chezmoi's normal exceptions. Edit managed source files and commit their changes.
The workspace uses a relative root and works regardless of checkout location.

## Platform paths

Neovim uses `$XDG_CONFIG_HOME/nvim`, falling back to `~/.config/nvim`, on macOS and
Linux. At the default location, chezmoi manages its files directly. A nondefault
absolute XDG location uses a directory symlink to the same tracked tree, maintained
by a native script; this also supports a location outside HOME.

Windows uses `$LOCALAPPDATA/nvim`, with a native symlink template for the standard
`~/AppData/Local` location and a native PowerShell script for a redirected location.
The POSIX Neovim target is ignored on Windows. Enable Windows Developer Mode or
grant symbolic-link creation permission. Git must be on PATH on every platform.
Existing unrelated Neovim directories are refused and require review and backup.

Karabiner always uses `~/.config/karabiner` on macOS. zsh is ignored on Windows.
Git's portable include always lives at `~/.config/git/portable.inc`; its name avoids
Git's automatic loading of an XDG `git/config` file.

The include hook adds `.config/git/portable.inc` once to the machine-local
`~/.gitconfig`. Credential helpers, includeIf sections, and other local settings
remain there. Local overrides for portable settings can be placed after the include.
Do not add your entire machine-local Git configuration to chezmoi.

The macOS preferences script uses `defaults` directly and reruns when its contents
change. Log out or restart affected applications if needed for preference changes.
Karabiner automatic backups and generated Neovim cache files are not managed.

## Migration history

The old component framework is replaced by native chezmoi source names, ignores,
templates, and run scripts. The `pre-chezmoi-migration` tag preserves the previous
implementation. The current decision is documented in `docs/adr/0001-chezmoi.md`.
Legacy tracked Karabiner backups, if present, are retained under `docs/legacy-karabiner/`.
