# ADR-0007: Keep checkout location out of component manifests

- Status: Accepted
- Date: 2026-09-06

## Context

Symlink-mode configs benefit from a stable physical checkout path, but hard-coding a checkout location inside component metadata would make dotfiles less portable.

## Decision

Component manifests never contain the dotfiles checkout path. Setup derives the source from the directory in which the repository is actually checked out.

`~/.dotfiles` is the canonical checkout convention used by `machines`, but it is not a requirement of this repository.

## Consequences

- Dotfiles can still be cloned elsewhere intentionally.
- `machines` can provide a stable default without creating a reverse dependency.
- Manifests remain machine-independent.
