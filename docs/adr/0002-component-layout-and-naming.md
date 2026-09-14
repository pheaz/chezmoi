# ADR-0002: Package components under `components/`

- Status: Accepted
- Date: 2026-09-06
- Revised: 2026-09-14

## Context

The original layout stored each application's raw configuration directly at the repository root and kept metadata separately under `configs/`. That worked while components contained only configuration files, but it does not provide a clean home for component-specific metadata or exceptional setup behavior.

Component directories should remain understandable without `machines`, and scripts must never be mixed into the file tree exposed directly to an application.

## Decision

All managed configuration is organized as self-contained components below `components/<component>/`.

A component uses these names:

- `files/` — the static managed file tree. Only files intended to be consumed or installed for the application belong here; setup scripts never do.
- `manifest.yaml` — component detection, installation mode, and platform-specific natural targets.
- `setup.sh` and `setup.ps1` — optional component-owned integration scripts, used only by `setup` mode.

Components are named after the concrete configuration subject rather than a logical role from another repository. Examples include `nvim`, `karabiner`, and `gitconfig`.

The `files/` wrapper is intentional: the component root now contains both managed files and component metadata/behavior, so the wrapper preserves an exact application-facing filesystem tree.

## Consequences

- Everything specific to one component is colocated below one directory.
- `files/` remains safe to symlink or copy as a complete tree.
- Component-specific scripts cannot leak into an application's natural config directory.
- Metadata no longer requires a parallel `configs/` hierarchy.
- Dotfiles naming remains independent of logical roles in `machines`.
