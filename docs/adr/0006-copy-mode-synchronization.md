# ADR-0006: Use status/apply/capture for copy-mode synchronization

- Status: Accepted
- Date: 2026-09-06

## Context

Copy-mode components necessarily have two physical copies. Manual copying between them is error-prone, but the dotfiles tooling should not reimplement Git history or silently overwrite either side.

## Decision

Copy-mode components use three explicit operations:

- `status` — compare repo and live config without changing either side;
- `apply` — copy repo to the natural location only when the target is absent;
- `capture` — copy the natural location into the repo working tree.

`capture` refuses to run over existing uncommitted changes for that component and leaves the result uncommitted for normal Git review.

## Consequences

- Git remains the only history and rollback system.
- Dotfiles only handles filesystem synchronization.
- Existing live configs are never silently overwritten.
