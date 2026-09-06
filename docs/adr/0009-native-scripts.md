# ADR-0009: Use native scripts instead of a general-purpose dotfile manager

- Status: Accepted
- Date: 2026-09-06

## Context

A general-purpose manager such as chezmoi would add another abstraction layer and repository format. The desired behavior is small and explicit: detection, target resolution, linking/copying, and safe synchronization.

## Decision

Use repository-owned setup scripts and simple manifests rather than adopting chezmoi or another general-purpose dotfile manager.

## Consequences

- Repository structure remains transparent.
- Behavior is tailored to the actual needs of this setup.
- Cross-platform behavior must be maintained in the repository's own scripts.
