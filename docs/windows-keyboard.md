# Windows keyboard: US-International (AltGr, no dead keys)

Tracked source: [`../configs/windows-keyboard/us_international_no_dead_keys.klc`](../configs/windows-keyboard/us_international_no_dead_keys.klc).

- Display name: **United States-International - AltGr - No Dead Keys**
- Layout identifier in the MSKLC source: `USIntGr`
- Language: `en-US` (`00000409`)
- Original attribution in the source: (c) 2017 Daniels Umanovskis
- Original file SHA-256: `770e1e48639a6658ba8213464607479c2cdd4a457273ef9fc7fb2cf7ce9a5868`

The uploaded `.klc` source is stored **byte-for-byte**, including UTF-16
little-endian with BOM and CRLF line endings; Git is configured not to apply
text conversion to `.klc` files. Do not reformat it to avoid unintentional
layout changes.

## Install on another Windows computer

1. Initialize this repository with `chezmoi init --apply pheaz/chezmoi`,
   or update an existing checkout with `chezmoi update`.
2. Install [Microsoft Keyboard Layout Creator 1.4](https://www.microsoft.com/en-us/download/details.aspx?id=102134).
   Microsoft lists Windows 10 support; building on Windows 11 can require
   compatibility workarounds, so its availability there is not guaranteed.
3. In MSKLC, choose **File > Load Source File** and open
   `%USERPROFILE%\.local\share\chezmoi\configs\windows-keyboard\us_international_no_dead_keys.klc`.
4. Choose **Project > Build DLL and Setup Package**. Keep the generated
   installer files together, and run its `setup.exe` on the target PC
   (administrator approval may be required).
5. Sign out and back in or restart Windows if necessary. Under **Settings >
   Time & language > Language & region > English (United States) > Language
   options > Keyboards**, add/select **United States-International - AltGr -
   No Dead Keys**. Windows 10 menu labels may vary.
6. Verify the selected keyboard with **Win + Space** and test AltGr characters.

If a working setup package was previously generated on the original machine,
you can reuse it on a compatible target instead of rebuilding the `.klc`.
The installer package itself is **not** included in this repository.

## Scope

The repository intentionally excludes `configs/` from chezmoi home targets.
The tracked `.klc` source is available in the chezmoi source checkout, but
**`chezmoi apply` does not install or activate the layout**: Windows needs a
compiled keyboard DLL and registered layout, which the generated installer
provides.

The `.klc` does **not** specify the user's entire Windows language list,
preferred-language order, display language, regional settings, or default input
method. Export and restore those preferences separately, installing this
keyboard before restoring a language list that references it. Do not copy
machine-specific registry keys or keyboard DLLs into the repo as a substitute
for a supported installer.
