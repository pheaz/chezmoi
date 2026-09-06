# Dotfiles

Personal configuration files shared across machines.

## Layout

- `nvim/` — repository copy of the Neovim configuration
- `dotfiles.code-workspace.template` — portable VS Code workspace template
- `setup.sh` — compare/install/workspace helpers for macOS/Linux
- `setup.ps1` — compare/install/workspace helpers for Windows

Configs remain in their applications' natural locations. The repository keeps a separate tracked copy and the setup scripts compare the two without overwriting existing files.

## VS Code workspace

The tracked workspace template contains the dotfiles repository root and a placeholder for the machine's live Neovim config directory. Generate the machine-local workspace after cloning or pulling the repo.

macOS/Linux:

```sh
./setup.sh workspace
```

Windows PowerShell:

```powershell
.\setup.ps1 workspace
```

This creates `dotfiles.code-workspace` in the repository root. The generated file is ignored by Git because it contains machine-specific absolute paths.

Resolved Neovim paths:

- macOS/Linux: `${XDG_CONFIG_HOME:-$HOME/.config}/nvim`
- Windows: `%LOCALAPPDATA%\nvim`

Open the generated workspace with VS Code:

```sh
code dotfiles.code-workspace
```

## Neovim

Natural config locations:

- macOS/Linux: `~/.config/nvim` by default, or `$XDG_CONFIG_HOME/nvim` when `XDG_CONFIG_HOME` is set
- Windows: `%LOCALAPPDATA%\nvim`

### Compare

macOS/Linux:

```sh
./setup.sh nvim status
```

Windows PowerShell:

```powershell
.\setup.ps1 nvim status
```

For each tracked file, the status command compares the live file with the repo copy. If they differ, it searches Git history for an exact content match and uses commit ancestry to determine whether the live copy is a known older version, a known newer version, divergent, or unknown.

Existing files are never overwritten by `status`.

### Install when missing

If the natural config directory does not exist:

```sh
./setup.sh nvim install
```

or on Windows:

```powershell
.\setup.ps1 nvim install
```

`install` refuses to replace an existing config directory.

Symlink-based config setups are not supported.
