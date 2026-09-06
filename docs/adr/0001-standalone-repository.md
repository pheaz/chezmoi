# ADR-0001: Keep dotfiles standalone

- Status: Accepted
- Date: 2026-09-06

## Context

`dotfiles` is useful both when invoked by machine provisioning and when cloned onto an already configured machine. Depending on `machines` would reverse the intended dependency direction and make standalone use fragile.

## Decision

`dotfiles` must never depend on the `machines` repository.

Any runtime prerequisite needed by dotfiles must be handled by dotfiles itself or documented as a standalone prerequisite. `machines` may independently use the same tool, but dotfiles must not assume that `machines` ran first or installed it.

In particular, the current use of `yq` must not rely on `machines` for installation. Dotfiles must eventually bootstrap that dependency itself or remove it.

## Consequences

- `dotfiles` can be cloned and used independently.
- No imports, source-file references, generated data, or setup ordering from `machines` are allowed.
- Shared behavior flows from `dotfiles` to `machines` through invocation, never the reverse.
