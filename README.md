# Dotfiles

Personal configuration files shared across machines.

## Layout

- `nvim/` — repository copy of the Neovim configuration
- `setup.sh` — compare/install helpers for macOS/Linux
- `setup.ps1` — compare/install helpers for Windows

Configs remain in their applications' natural locations. The repository keeps a separate tracked copy and the setup scripts compare the two without overwriting existing files.

## Neovim

Natural config locations:

- macOS/Linux: `~/.config/nvim`
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
