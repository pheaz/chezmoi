# ADR-0002: Name components after actual applications

- Status: Accepted
- Date: 2026-09-06

## Context

`machines` may use logical roles such as `terminal` that resolve to different applications on each platform. Dotfiles should describe the concrete application whose files are being configured.

## Decision

Each dotfiles component is named after the actual application, not a logical role from another repository.

Examples:

- `iterm2/`
- `windows-terminal/`
- `nvim/`

Each component stores its real tracked config directly in `<component>/`. Metadata lives separately in `configs/<component>.yaml`; there is no extra `files/` wrapper directory.

## Consequences

- Dotfiles naming remains understandable without `machines`.
- Different platform implementations of one logical role can have separate components.
- Component directories remain directly usable as configuration trees.
