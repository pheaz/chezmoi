# Windows keyboard: US International – AltGr – No Dead Keys

This repository tracks the editable source and an MSKLC-generated installer
bundle for the custom `USIntAlt` keyboard layout. The key mappings are unchanged
from the original `USIntGr` source; only the MSKLC internal name and display
description were renamed to avoid a duplicate-identity build error.

- Source: [`../configs/windows-keyboard/usintalt.klc`](../configs/windows-keyboard/usintalt.klc)
- Installer: `configs/windows-keyboard/installer/USIntAlt-x64.zip`
- Bundle SHA-256: `55f63cb22519aaf7eda167145a8ac7a223b1dcf0e1d622a8f2599f7b2bd564e7`
- Bundle contents: `USIntAlt_amd64.msi`, `amd64/USIntAlt.dll`, `wow64/USIntAlt.dll`
- MSI SHA-256: `2c112553b37257b7c5b9601b84753eb514ec0efed3265a2adaa9a356bbd71733`
- AMD64 DLL SHA-256: `1244024ad4c10893ba472cbac89d5dc2dcf2e173ba52655902ce4bc584664ec3`
- Keyboard display name: `US International - AltGr - No Dead Keys`
- Keyboard internal name and driver filename: `USIntAlt`, `usintalt.dll`
- Language: `en-US` (`0409`); source attribution: Daniels Umanovskis, 2017

The `.klc` source is kept in its native UTF-16 LE format. The `.zip` is derived
from the user-supplied MSKLC setup package, retaining the x64 MSI and both DLL
subdirectories that the installer may require. Generated Itanium, standalone
`setup.exe`, and 32-bit installer files are excluded because this deployment
is intentionally scoped to x64 Windows.

## Fresh x64 Windows setup

1. Install Git and chezmoi, and authenticate for the private repository.
2. Run `chezmoi init --apply pheaz/chezmoi`, or `chezmoi update` on an existing
   checkout. Chezmoi invokes the Windows-specific PowerShell after-script.
3. Accept the Windows UAC prompt if the keyboard is not installed.
   The script verifies SHA-256 hashes, extracts the archive to a temporary
   directory, and runs `msiexec /i ... /qn /norestart`.
4. The script detects the registered KLID, adds its input method to `en-US`
   if needed, and selects it as the current user's default.
5. No automatic reboot is initiated. A Windows sign-out/restart may be needed
   before Windows fully exposes a newly installed keyboard. Verify with
   `Win + Space` and test an AltGr mapping.

The `run_after_50-windows-keyboard.ps1.tmpl` script is idempotent: on later
`chezmoi apply` runs, it skips installing an already registered matching
layout and only changes per-user input preferences when necessary. If a
registered `usintalt.dll` does not match the tracked DLL, it stops rather than
overwriting it. The previous `USIntGr` keyboard is not removed or modified.

## Limitations

- This deployment supports **x64 Windows only**. ARM64 and 32-bit Windows
  are not modified by the script.
- Installing a keyboard layout driver requires administrator approval.
  Selecting the input method runs in the context of the current Windows user.
- Only the *default keyboard input method* is configured, not the full
  preferred-language order, display language, culture, or system locale.
- The supplied MSKLC output and package hashes were inspected, but an actual
  installation and key mapping test on a new Windows machine was **not** run.

To rebuild, load `usintalt.klc` in Microsoft Keyboard Layout Creator and use
**Project → Build DLL and Setup Package**. Update the tracked ZIP and SHA-256
values together when the package intentionally changes.
