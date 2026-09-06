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

A component may intentionally omit targets for platforms it does not support. Automatic setup skips that component on an unsupported platform. Explicit component commands report that the component has no target for the current platform.

## Consequences

- `machines` does not maintain package-to-config mappings.
- Dotfiles can auto-configure supported applications already present on a machine.
- Platform-specific applications can be represented without fake targets for other platforms.
- Application config knowledge has one owner.
