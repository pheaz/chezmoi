# Architecture Decision Records

All architectural decisions for this repository are recorded here. Accepted ADRs are the source of truth for implementation direction.

- [ADR-0001: Keep dotfiles standalone](0001-standalone-repository.md)
- [ADR-0002: Package components under `components/`](0002-component-layout-and-naming.md)
- [ADR-0003: Dotfiles owns detection and natural config targets](0003-detection-and-target-ownership.md)
- [ADR-0004: Use per-component installation modes](0004-per-component-installation-modes.md)
- [ADR-0005: Natural config paths symlink into the repo](0005-symlink-direction.md)
- [ADR-0006: Use status/apply/capture for copy-mode synchronization](0006-copy-mode-synchronization.md)
- [ADR-0007: Keep checkout location out of component manifests](0007-checkout-location.md)
- [ADR-0008: Track a relative VS Code workspace](0008-relative-vscode-workspace.md)
- [ADR-0009: Use native scripts instead of a general-purpose dotfile manager](0009-native-scripts.md)
- [ADR-0010: Bootstrap direct prerequisites locally](0010-bootstrap-direct-prerequisites.md)
- [ADR-0011: Modularize native setup by platform and responsibility](0011-modular-native-setup.md)
- [ADR-0012: Add component-owned `setup` mode](0012-component-owned-setup-mode.md)
