# ADR-0005: Natural config paths symlink into the repo

- Status: Accepted
- Date: 2026-09-06

## Context

For symlink-mode components, one side must be the physical source of truth. The repository should remain the tracked source rather than becoming a link to mutable application state elsewhere.

## Decision

The application's natural config path contains the symlink, and that symlink points to the tracked component directory inside the dotfiles checkout.

Example:

```text
~/.config/nvim -> ~/.dotfiles/nvim
```

The reverse direction is not used.

## Consequences

- The Git checkout is the physical source of truth.
- Editing through the application's natural path edits tracked files directly.
- No `capture` operation is needed once the link is established.
- Moving the checkout requires repairing links, which is mitigated by the stable checkout convention recorded separately.
