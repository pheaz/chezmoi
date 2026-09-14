# ADR-0007: Keep checkout location out of component manifests

- Status: Accepted
- Date: 2026-09-06
- Revised: 2026-09-14

## Context

Symlink-mode configs and setup-mode integrations may need the physical path of tracked component files, but hard-coding a checkout location inside component metadata would make dotfiles less portable.

## Decision

Component manifests never contain the dotfiles checkout path. Setup derives component paths from the directory in which the repository is actually checked out, including `components/<component>/files/` and any component-owned setup scripts.

`~/.dotfiles` is the canonical checkout convention used by `machines`, but it is not a requirement of this repository.

## Consequences

- Dotfiles can still be cloned elsewhere intentionally.
- `machines` can provide a stable default without creating a reverse dependency.
- Manifests remain machine-independent.
- Component setup scripts receive paths derived from the actual checkout rather than embedding one.
