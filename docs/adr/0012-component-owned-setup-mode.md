# ADR-0012: Add component-owned `setup` mode

- Status: Accepted
- Date: 2026-09-14

## Context

Some configuration cannot safely be installed by replacing its natural target with a symlink or copy. Global Git configuration is one example: portable settings should be tracked, while machine-specific credential helpers and authentication integration must remain local to each machine.

Encoding application-specific commands in manifests would turn the manifest format into a scripting language, while putting application adapters under `lib/` would mix concrete component behavior with reusable setup mechanisms.

## Decision

Add a third installation mode named `setup`.

A setup-mode component may provide native scripts at its component root:

```text
components/<component>/setup.sh
components/<component>/setup.ps1
```

Its static managed payload remains under `files/` and scripts never live in that directory.

The root setup entrypoints remain the public CLI. They invoke the platform-appropriate component script for explicit `status` and `apply` actions. Automatic setup invokes `apply`; therefore component setup scripts must be idempotent. `capture` is not supported for setup-mode components because there is no generic filesystem synchronization contract to apply.

The root passes the action, component `files/` path, and resolved natural target to the component script. Reusable behavior still belongs in `lib/`; setup-mode scripts are reserved for behavior specific to the component they live with.

## Consequences

- Components with native include/import/registration mechanisms do not need unsafe symlink or copy workarounds.
- Application-specific behavior remains colocated with its component.
- `lib/` remains organized around reusable responsibilities rather than application adapters.
- Setup scripts must be implemented separately for each supported runtime when cross-platform behavior is required.
