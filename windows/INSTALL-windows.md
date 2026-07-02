# Windows host install

This directory contains everything that runs **on the Windows 11 host**
(not inside WSL). The WSL guest config lives in [`../wsl/`](../wsl/).

## Files

| File | Purpose |
|------|---------|
| `bootstrap.ps1` | One-shot Windows host setup: WSL2 features, winget apps, scoop CLI tools, Windows Terminal config, Cursor config, AutoHotkey GNOME keybindings, PowerShell profile. |
| `winget-packages.txt` | App IDs installed via winget (Windows Terminal, Git, Cursor, VS Code, PowerToys, **AutoHotkey**, JetBrains Mono, …). |
| `scoop-packages.txt` | CLI tools installed via scoop (mirrors the repo's Brewfile so you get `bat`/`fd`/`fzf`/`eza`/`ripgrep`/`delta`/`lazygit`/… on the Windows PATH). |
| `windows-terminal/settings.json` | Windows Terminal config with a generated **Kanagawa Wave** color scheme and the Fedora WSL distro as the default profile. |
| `powershell/Microsoft.PowerShell_profile.ps1` | Minimal PowerShell profile with aliases mirroring the zsh aliases in `../zsh/config/aliases`. |
| `ahk/gnome-keybindings.ahk` | AutoHotkey v2 script that replicates every binding from `gnome/keybindings.ini` (close, maximize/minimize/restore, snap left/right, move-to-monitor, screenshot UI, lock screen, launch terminal). Auto-started at login by `bootstrap.ps1` via a shortcut in the Startup folder. |
| `enable-super-l.ps1` | One-off admin helper that disables Windows' built-in `Win+L` lock handler so `Super+l` can be remapped to "snap window right" (matching GNOME). `Super+q` takes over locking via the Windows API. Run once, reboot; `-Revert` restores default Win+L. |

## Quick start (from the cloned repo root)

```powershell
powershell -ExecutionPolicy Bypass -File windows\bootstrap.ps1
```

The script reboots once if it had to enable the WSL2 features; rerun it after
the reboot (`-SkipWsl` is fine the second time if you already ran
`wsl\setup-wsl.ps1`). All steps are idempotent and accept `-WhatIf`.

## What `bootstrap.ps1` does, step by step

1. Enables `VirtualMachinePlatform` + `Microsoft-Windows-Subsystem-Linux` and
   sets WSL default version to 2 (reboots if needed).
2. Installs every ID in `winget-packages.txt` with `winget install -e --silent`.
3. Bootstraps **scoop** (user-scope, no admin) then installs every package in
   `scoop-packages.txt`.
4. Copies `windows-terminal/settings.json` into the Windows Terminal
   `LocalState` directory (replacing the default config).
5. Runs `cursor/windows-profile.ps1` to link `cursor/settings.json` +
   `cursor/keybindings.json` into `%APPDATA%\Cursor\User` and install every
   extension in `cursor/extensions.txt`.
6. Installs the **GNOME keybindings** AutoHotkey script
   (`windows/ahk/gnome-keybindings.ahk`) and drops a shortcut in the
   Startup folder so it runs at every login. Every binding from
   `gnome/keybindings.ini` now maps to the Windows equivalent
   (Super+w close, Super+k maximize, Super+h/l snap left/right,
   Shift+Super+h/l move-to-monitor, Shift+Super+s Snipping Tool,
   Super+q lock, Super+Enter → Windows Terminal).

   **One-off admin step (only for Super+l):** Windows reserves `Win+L` for
   lock. To free it so `Super+l` snaps right, run once as admin then reboot:
   ```powershell
   powershell -ExecutionPolicy Bypass -File windows\enable-super-l.ps1
   ```
   `Super+q` keeps working as the lock key regardless (it calls the
   `LockWorkStation` API, not `Win+L`).

   > Snipping Tool (`Shift+Super+s`) and Windows Terminal (`Super+Enter`)
   > need no extra step; they're auto-installed by winget.

7. Symlinks `powershell/Microsoft.PowerShell_profile.ps1` to `$PROFILE`.
8. Hands off to `wsl/setup-wsl.ps1` (unless `-SkipWsl`).

## Sanity checks after running

```powershell
winget --version
scoop --version
bat --version
fd --version
fastfetch
```

Open Windows Terminal: the default profile should be **Fedora 43 (WSL)** and
the color scheme should be Kanagawa Wave (dark, dim amber-green palette).