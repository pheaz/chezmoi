# ADR-0004: Use per-component installation modes

- Status: Accepted
- Date: 2026-09-06

## Context

Some applications work well with symlinked configuration while others need real files in their natural locations. Forcing one strategy on every application creates unnecessary synchronization or compatibility problems.

## Decision

Each component declares an installation mode in its manifest.

Supported modes are:

- `symlink` — preferred when the application supports it reliably;
- `copy` — used when symlinks are unsuitable.

A new mode requires a new ADR rather than being added implicitly.

## Consequences

- Symlink-friendly applications have one source of truth.
- Copy-only applications retain explicit synchronization semantics.
- Strategy is decided per application rather than globally.
