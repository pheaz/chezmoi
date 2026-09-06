# ADR-0003: Dotfiles owns detection and natural config targets

- Status: Accepted
- Date: 2026-09-06

## Context

Application detection and natural config locations are application- and platform-specific. Duplicating that knowledge in provisioning would couple the repositories and create drift.

## Decision

Dotfiles owns, per component:

- how to detect whether the application is installed;
- the natural config target for each supported platform;
- the installation mode used for that component.

This metadata is stored in `configs/<component>.yaml`. The tracked source is implicit as `<repo>/<component>`.

## Consequences

- `machines` does not maintain package-to-config mappings.
- Dotfiles can auto-configure supported applications already present on a machine.
- Application config knowledge has one owner.
