# Dotfiles

Personal configuration files shared across machines.

## Layout

- `<component>/` — tracked copy of an application's configuration.
- `configs/<component>.yaml` — detection and natural-location metadata for that component.
- `dotfiles.code-workspace.template` — portable VS Code workspace template.
- `setup.sh` — config synchronization helper for macOS/Linux.
- `setup.ps1` — config synchronization helper for Windows.

Configs remain in their applications' natural locations. The repository keeps a separate tracked copy; Git remains the source of history and rollback.

## Automatic setup

Run the setup script with no component to inspect every manifest, detect supported applications, and configure the ones that are installed:

macOS/Linux:

```sh
./setup.sh
```

Windows PowerShell:

```powershell
.\setup.ps1
```

For each detected application, a missing natural config is populated from the repo. An existing config is compared with the repo and never overwritten automatically.

`yq` is required to read the YAML manifests. The `machines` bootstrap installs it before invoking dotfiles setup.

## Component manifests

A manifest stores where an application's real config lives and how to detect the application. The manifest filename matches the tracked config directory.

```yaml
# configs/nvim.yaml
detect:
  command: nvim

target:
  windows: "$LOCALAPPDATA/nvim"
  macos: "$XDG_CONFIG_HOME/nvim"
  linux: "$XDG_CONFIG_HOME/nvim"
```

On macOS/Linux, `$XDG_CONFIG_HOME` falls back to `~/.config` when unset.

## Synchronization

Each component supports three directions/actions.

### Status

Compare the natural config with the tracked repo copy without changing either side:

```sh
./setup.sh nvim status
```

```powershell
.\setup.ps1 nvim status
```

The comparison uses Git object hashes and history to distinguish files that are equal, known older/newer versions, missing, local-only, or unknown/divergent.

### Apply

Copy the tracked repo config into the application's natural location:

```sh
./setup.sh nvim apply
```

```powershell
.\setup.ps1 nvim apply
```

`apply` only works when the natural config directory is absent. It refuses to replace an existing config.

### Capture

Copy the application's live config back into the repo working tree:

```sh
./setup.sh nvim capture
```

```powershell
.\setup.ps1 nvim capture
```

`capture` refuses to run when that component already has uncommitted repo changes. The previous committed repo state remains recoverable through Git, and the resulting working-tree changes are shown with `git status`/`git diff` for normal review and commit.

Symlink-based config setups are not supported.

## VS Code workspace

Generate the machine-local workspace after cloning or pulling the repo:

```sh
./setup.sh workspace
```

```powershell
.\setup.ps1 workspace
```

The generated `dotfiles.code-workspace` is ignored by Git because it contains a machine-specific absolute Neovim config path resolved from `configs/nvim.yaml`.
