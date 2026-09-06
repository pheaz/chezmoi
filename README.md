# Dotfiles

Personal configuration files shared across machines.

The canonical checkout used by `machines` is `~/.dotfiles`. The setup scripts themselves do not depend on that path: they derive every config source from the location of the repository, so the repo can still be cloned elsewhere intentionally.

## Layout

- `<component>/` — the tracked application configuration.
- `configs/<component>.yaml` — detection, installation mode, and natural target location.
- `dotfiles.code-workspace` — tracked VS Code workspace using only relative paths.
- `setup.sh` — setup helper for macOS/Linux.
- `setup.ps1` — setup helper for Windows.

## Component manifests

Each application owns a small manifest. The filename matches the tracked config directory.

```yaml
# configs/nvim.yaml
detect:
  command: nvim

mode: symlink

target:
  windows: "$LOCALAPPDATA/nvim"
  macos: "$XDG_CONFIG_HOME/nvim"
  linux: "$XDG_CONFIG_HOME/nvim"
```

On macOS/Linux, `$XDG_CONFIG_HOME` falls back to `~/.config` when unset.

The source is implicit: `configs/nvim.yaml` configures the tracked `nvim/` directory in this repository. No checkout path is stored in the manifest.

## Modes

### `symlink`

Preferred when the application works normally with symlinked configuration.

For Neovim, a checkout at `~/.dotfiles` produces:

```text
~/.config/nvim -> ~/.dotfiles/nvim
```

On Windows the equivalent target is `%LOCALAPPDATA%\nvim` and points to the repository's `nvim` directory.

There is only one copy of the configuration, so edits made through either path immediately modify the Git working tree.

If the natural target already exists as a real directory, setup refuses to replace it. `status` compares that directory with the repo first, and `capture` can import it into the repo working tree before migration if needed.

### `copy`

Available for applications that should not or cannot use symlinks. The repo and natural application location are separate copies.

For copy-mode components:

- `status` compares the two copies and uses Git history when possible to identify known older/newer versions.
- `apply` copies the repo configuration to a missing natural location.
- `capture` copies a real natural config directory back into the repo working tree.

`capture` refuses to overwrite existing uncommitted changes for that component. Git remains the source of history and rollback.

## Automatic setup

Run setup with no component to inspect every manifest, detect installed applications, and configure them according to their mode:

macOS/Linux:

```sh
./setup.sh
```

Windows PowerShell:

```powershell
.\setup.ps1
```

A missing symlink-mode target is linked into the repo. A missing copy-mode target is copied from the repo. Existing targets are inspected rather than overwritten.

`yq` is required to read the YAML manifests. The `machines` bootstrap installs it before invoking dotfiles setup.

## Component commands

Inspect a component:

```sh
./setup.sh nvim status
```

```powershell
.\setup.ps1 nvim status
```

Apply its configured strategy:

```sh
./setup.sh nvim apply
```

```powershell
.\setup.ps1 nvim apply
```

Capture an existing real config directory into the repo working tree when needed:

```sh
./setup.sh nvim capture
```

```powershell
.\setup.ps1 nvim capture
```

Once a symlink-mode component is correctly linked, `capture` is unnecessary because the application is already editing the tracked files directly.

## VS Code workspace

`dotfiles.code-workspace` is tracked directly and contains only the repository root as a relative folder. No machine-specific generation step is required.

Open it with:

```sh
code ~/.dotfiles/dotfiles.code-workspace
```
