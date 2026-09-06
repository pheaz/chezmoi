# Dotfiles

Personal configuration files shared across machines.

The setup scripts are standalone and derive config sources from the repository location. `~/.dotfiles` is the canonical checkout used by `machines`, but the repo can be cloned elsewhere intentionally.

## Architecture decisions

Accepted architectural decisions live in [`docs/adr/`](docs/adr/). New architectural changes should be recorded there before implementation changes are made.

A core boundary is that `dotfiles` never depends on `machines`. Any prerequisite needed by dotfiles must be satisfied by dotfiles itself or be an explicit standalone prerequisite; `machines` is never part of the contract.

## Layout

- `<component>/` — the tracked application configuration.
- `configs/<component>.yaml` — detection, installation mode, and natural target location.
- `lib/sh/` — internal macOS/Linux implementation modules.
- `lib/powershell/` — internal Windows implementation modules.
- `dotfiles.code-workspace` — tracked VS Code workspace using only relative paths.
- `setup.sh` — public macOS/Linux CLI and orchestration entrypoint.
- `setup.ps1` — public Windows CLI and orchestration entrypoint.

The root setup scripts own the command-line flow and dispatch. Substantial platform-specific behavior is split by responsibility into `prerequisites`, `manifests`, `symlink`, and `copy` modules under `lib/`.

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

```sh
./setup.sh
```

```powershell
.\setup.ps1
```

A missing symlink-mode target is linked into the repo. A missing copy-mode target is copied from the repo. Existing targets are inspected rather than overwritten.

The setup scripts use `yq` to read YAML manifests. If `yq` is already available, they use it. Otherwise they bootstrap the official precompiled binary into the user-local `.local/bin` directory, so a standalone dotfiles clone does not depend on `machines` or a system package manager for this prerequisite.

## Component commands

```sh
./setup.sh nvim status
./setup.sh nvim apply
./setup.sh nvim capture
```

Once a symlink-mode component is correctly linked, `capture` is unnecessary because the application is already editing the tracked files directly.

## VS Code workspace

`dotfiles.code-workspace` is tracked directly and contains only the repository root as a relative folder. No machine-specific generation step is required.
