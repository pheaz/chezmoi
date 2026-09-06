# ADR-0011: Modularize native setup by platform and responsibility

- Status: Accepted
- Date: 2026-09-06

## Context

The native `setup.sh` and `setup.ps1` implementations have grown large enough that unrelated concerns are difficult to navigate in a single file. At the same time, replacing the native implementations with another runtime solely to deduplicate code would introduce a new bootstrap and distribution concern.

A tiny root wrapper that only forwards into another monolithic file would move the problem rather than solve it. Splitting every helper function into its own file would create excessive navigation overhead.

## Decision

Keep `setup.sh` and `setup.ps1` as the public CLI and orchestration entrypoints.

Extract substantial implementation responsibilities into internal modules under `lib/`, organized first by platform/runtime and then by responsibility:

```text
lib/
├── sh/
│   ├── prerequisites.sh
│   ├── manifests.sh
│   ├── symlink.sh
│   └── copy.sh
└── powershell/
    ├── prerequisites.ps1
    ├── manifests.ps1
    ├── symlink.ps1
    └── copy.ps1
```

The root scripts own command-line parsing, setup flow, component dispatch, and automatic configuration orchestration.

The modules own these coherent concerns:

- `prerequisites` — tools directly required by dotfiles setup;
- `manifests` — platform resolution and component manifest interpretation;
- `symlink` — symlink-mode status and application;
- `copy` — comparison, Git-history classification, apply, and capture for real config trees.

Shell and PowerShell remain separate native implementations governed by the same ADRs, manifest schema, commands, safety rules, and user-visible semantics. Shared behavior is specified by those contracts rather than forced through a common runtime.

Do not add generic `core`, `common`, `utils`, or one-function modules without a concrete reusable responsibility.

## Consequences

- The public entrypoints still reveal the overall program flow.
- Large implementation concerns become easier to find and maintain.
- Shell and PowerShell implementations remain structurally parallel without mixing their files in one directory.
- Native implementation duplication remains explicit rather than being replaced by a new runtime dependency.
- Internal modules can be split further only when a real responsibility justifies it.
