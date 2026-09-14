# Dotfiles

Personal configuration files shared across machines.

The setup scripts are standalone and derive component sources from the repository location. `~/.dotfiles` is the canonical checkout used by `machines`, but the repo can be cloned elsewhere intentionally.

## Architecture decisions

Accepted architectural decisions live in [`docs/adr/`](docs/adr/). New architectural changes should be recorded there before implementation changes are made.

A core boundary is that `dotfiles` never depends on `machines`. Any prerequisite needed by dotfiles must be satisfied by dotfiles itself or be an explicit standalone prerequisite; `machines` is never part of the contract.

## Layout

- `components/<component>/files/` — the tracked files managed for that component; setup scripts never live here.
- `components/<component>/manifest.yaml` — detection, installation mode, and natural target location.
- `components/<component>/setup.sh` / `setup.ps1` — optional component-owned setup behavior for `setup` mode.
- `lib/sh/` — internal macOS/Linux implementation modules shared across components.
- `lib/powershell/` — internal Windows implementation modules shared across components.
- `dotfiles.code-workspace` — tracked VS Code workspace using only relative paths.
- `setup.sh` — public macOS/Linux CLI and orchestration entrypoint.
- `setup.ps1` — public Windows CLI and orchestration entrypoint.

The root setup scripts own the command-line flow and dispatch. Substantial reusable platform-specific behavior is split by responsibility into modules under `lib/`. Component-specific setup behavior stays with the component instead of being generalized prematurely.

## Components

Each component is self-contained below `components/`. Its manifest describes how the application is detected, where its natural configuration lives on each platform, and how its managed files are installed.

```yaml
# components/nvim/manifest.yaml
detect:
  command: nvim

mode: symlink

target:
  windows: "$LOCALAPPDATA/nvim"
  macos: "$XDG_CONFIG_HOME/nvim"
  linux: "$XDG_CONFIG_HOME/nvim"
```

On macOS/Linux, `$XDG_CONFIG_HOME` falls back to `~/.config` when unset.

The source is implicit: `components/nvim/manifest.yaml` configures `components/nvim/files/`. No checkout path is stored in the manifest.

A component may omit targets for platforms it does not support. Automatic setup skips those components on unsupported platforms; explicit component commands report that no target exists for the current platform.

## Modes

### `symlink`

Preferred when the application works normally with symlinked configuration.

For Neovim, a checkout at `~/.dotfiles` produces:

```text
~/.config/nvim -> ~/.dotfiles/components/nvim/files
```

There is only one copy of the managed files, so edits made through either path immediately modify the Git working tree.

If the natural target already exists as a real directory, setup refuses to replace it. `status` compares that directory with the repo first, and `capture` can import it into the component's `files/` tree before migration if needed.

### `copy`

Available for applications that should not or cannot use symlinks. The component files and natural application location are separate copies.

For copy-mode components:

- `status` compares the two copies and uses Git history when possible to identify known older/newer versions.
- `apply` copies the component files to a missing natural location.
- `capture` copies a real natural config directory back into the component's `files/` tree.

`capture` refuses to overwrite existing uncommitted changes for that component. Git remains the source of history and rollback.

### `setup`

Used when an application has installation semantics that cannot be represented correctly as a filesystem symlink or copy.

A setup-mode component owns `setup.sh` and/or `setup.ps1` at its component root. The root setup entrypoints dispatch `status` and `apply` to those scripts. Automatic setup invokes `apply`, so setup scripts must be idempotent. `capture` is not supported for setup-mode components.

`gitconfig` uses this mode. Its tracked `files/.gitconfig` contains portable Git settings, while the machine-local `~/.gitconfig` remains free to contain OS-specific credential helpers. Setup registers the tracked file through Git's global `include.path` rather than replacing the machine-local file.

## Automatic setup

Run setup with no component to inspect every component manifest, detect installed applications, and configure them according to their mode:

```sh
./setup.sh
```

```powershell
.\setup.ps1
```

A missing symlink-mode target is linked into the component's `files/` tree. A missing copy-mode target is copied from it. Existing targets are inspected rather than overwritten. Setup-mode components run their idempotent `apply` action. Components without a target for the current platform are skipped.

The setup scripts use `yq` to read YAML manifests. If `yq` is already available, they use it. Otherwise they bootstrap the official precompiled binary into the user-local `.local/bin` directory, so a standalone dotfiles clone does not depend on `machines` or a system package manager for this prerequisite.

## Component commands

```sh
./setup.sh nvim status
./setup.sh nvim apply
./setup.sh nvim capture
./setup.sh gitconfig status
./setup.sh gitconfig apply
```

Once a symlink-mode component is correctly linked, `capture` is unnecessary because the application is already editing the tracked files directly.

## VS Code workspace

`dotfiles.code-workspace` is tracked directly and contains only the repository root as a relative folder. No machine-specific generation step is required.
