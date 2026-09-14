# ADR-0005: Natural config paths symlink into the repo

- Status: Accepted
- Date: 2026-09-06
- Revised: 2026-09-14

## Context

For symlink-mode components, one side must be the physical source of truth. The repository should remain the tracked source rather than becoming a link to mutable application state elsewhere.

## Decision

The application's natural config path contains the symlink, and that symlink points to the component's tracked `files/` directory inside the dotfiles checkout.

Example:

```text
~/.config/nvim -> ~/.dotfiles/components/nvim/files
```

The reverse direction is not used.

Before the initial symlink is established, `capture` may initialize a missing `files/` directory from an existing real natural config directory. The captured files are left uncommitted for normal Git review. Once the natural path is linked into the repo, capture is unnecessary.

## Consequences

- The Git checkout is the physical source of truth after migration.
- Editing through the application's natural path edits tracked files directly.
- Existing application configuration can be imported without committing placeholder source files first.
- No `capture` operation is needed once the link is established.
- Moving the checkout requires repairing links, which is mitigated by the stable checkout convention recorded separately.
