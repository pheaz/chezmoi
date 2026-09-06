# ADR-0008: Track a relative VS Code workspace

- Status: Accepted
- Date: 2026-09-06

## Context

The earlier generated workspace existed to include both the repository and a separate live Neovim config path. Symlink mode makes those the same files.

## Decision

Track `dotfiles.code-workspace` directly in the repository and use only relative paths. Do not generate a machine-local workspace file or include duplicate live config folders.

## Consequences

- No workspace generation command is needed.
- The workspace is portable across checkout locations and platforms.
- The same files are not shown twice through repo and symlink paths.
