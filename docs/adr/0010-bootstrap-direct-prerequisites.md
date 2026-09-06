# ADR-0010: Bootstrap direct prerequisites locally

- Status: Accepted
- Date: 2026-09-06

## Context

`dotfiles` must remain usable when cloned independently of `machines`. The setup scripts currently use `yq` to read component manifests, so assuming another repository installed it would violate ADR-0001.

At the same time, another repository may legitimately need the same external tool for its own data. Preventing both repositories from independently ensuring that prerequisite would create artificial coupling.

## Decision

Each repository is responsible for external prerequisites that its own scripts directly require.

For `dotfiles`, the setup scripts must ensure `yq` themselves. If `yq` is not already available, they bootstrap the official precompiled binary into a user-local tool directory and use it from there.

Independent prerequisite bootstrapping in another repository is allowed. This is not considered duplication of dotfiles domain logic.

What must not be duplicated outside dotfiles is application-configuration behavior owned here, including detection, natural target paths, component modes, symlink behavior, and copy synchronization.

## Consequences

- A standalone dotfiles clone does not require `machines` to have run first.
- Dotfiles does not require a system package manager merely to obtain `yq`.
- Shared external tools may be installed independently by multiple repositories when each directly needs them.
- Repository-specific domain responsibilities remain single-owner even when low-level prerequisite checks are similar.
