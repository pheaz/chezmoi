# ADR-0004: Use per-component installation modes

- Status: Accepted
- Date: 2026-09-06
- Revised: 2026-09-14

## Context

Some applications work well with symlinked configuration while others need real files in their natural locations. A small number have application-specific installation semantics that cannot be represented correctly by either filesystem strategy.

## Decision

Each component declares an installation mode in its manifest.

Supported modes are:

- `symlink` — preferred when the application supports a direct link to its managed `files/` tree;
- `copy` — used when symlinks are unsuitable;
- `setup` — component-owned integration behavior, added by ADR-0012.

A new mode requires a new ADR rather than being added implicitly.

## Consequences

- Symlink-friendly applications have one source of truth.
- Copy-only applications retain explicit synchronization semantics.
- Exceptional application-specific behavior has an explicit mode instead of being hidden in generic filesystem logic.
- Strategy is decided per component rather than globally.
