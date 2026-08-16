# Dotfiles

Personal configuration files shared across machines.

## Layout

- `nvim/` — Neovim configuration
- `setup.sh` — links supported configs on macOS/Linux
- `setup.ps1` — links supported configs on Windows

The repository is intended to be cloned as `~/dotfiles`. Setup scripts create links from each program's expected config location back into this repository, so editing the live config edits the tracked file directly.

## Neovim

macOS/Linux:

```sh
./setup.sh nvim
```

Windows PowerShell:

```powershell
.\setup.ps1 nvim
```
