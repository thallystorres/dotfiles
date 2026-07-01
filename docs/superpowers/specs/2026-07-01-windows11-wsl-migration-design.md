# Design: Migrate dotfiles to Windows 11 + Fedora WSL

- **Date:** 2026-07-01
- **Status:** Approved
- **Author:** thallys (with opencode)

## 1. Context & goals

The current Fedora 43 machine is being wiped and replaced with Windows 11
on the **same hardware**. Fedora 43 will run inside WSL2 as the development
guest. The dotfiles repository (`/home/thallys/dotfiles`) remains the single
source of truth, but it must now drive three targets from one tree:

1. **Windows host** — Windows Terminal, Cursor, Git for Windows, fonts, scoop CLI tools.
2. **WSL guest (Fedora 43)** — zsh, tmux, nvim, vim, git, fastfetch, opencode, Codex CLI.
3. **Bare Linux / SSH hosts** — current behavior unchanged (GNOME + Ghostty + flatpaks).

Concrete deliverables:

1. **Restructure** the repo to add `windows/`, `wsl/`, `cursor/`, `scripts/`, `docs/` without dropping existing configs.
2. **Refactor bugs and bad configs** (typos, stale macOS paths, hardcoded `~/dotfiles`, drift between `extensions.txt` and `install_extensions.sh`).
3. **Add Cursor config** as a portable `cursor/` dir derived from `vscode/` plus a documented extraction recipe (`cursor/EXTRACT.md`) for the machine where Cursor actually lives.
4. **Add opencode + OpenAI Codex CLI** to the WSL bootstrap (both run inside WSL).
5. **Windows host bootstrap** (`windows/bootstrap.ps1`): winget + scoop + fonts + Windows Terminal + Cursor + Git.
6. **WSL guest bootstrap** (`wsl/setup-wsl.ps1`, `wsl/post-install.sh`): create Fedora-43 WSL distro, then run a refactored `install.sh` that is WSL-aware.
7. **End-to-end how-to** (`docs/HOWTO-from-poweron.md`): first power-up → fully working desktop + WSL dev box.

## 2. Repo layout (new/changed only)

```
dotfiles/
├── windows/                      # NEW
│   ├── bootstrap.ps1
│   ├── winget-packages.txt
│   ├── scoop-packages.txt
│   ├── windows-terminal/settings.json
│   ├── powershell/Microsoft.PowerShell_profile.ps1
│   └── INSTALL-windows.md
├── wsl/                          # NEW
│   ├── setup-wsl.ps1
│   ├── post-install.sh
│   ├── fedora.wslconfig
│   └── wsl.conf
├── cursor/                       # NEW
│   ├── settings.json
│   ├── keybindings.json
│   ├── extensions.txt
│   ├── install_extensions.sh
│   ├── windows-profile.ps1
│   └── EXTRACT.md
├── scripts/                      # NEW
│   ├── link_common.sh
│   └── gen-extension-installer.sh
├── docs/                         # NEW
│   ├── HOWTO-from-poweron.md
│   └── superpowers/specs/2026-07-01-windows11-wsl-migration-design.md  (this file)
├── fastfetch/config.jsonc                  # stays
├── fastfetch/config.wsl.jsonc              # NEW — WSL variant (no de/wm/theme/icons)
├── ghostty/                                # stays (applied only on bare Linux)
├── git/                                    # stays
├── gnome/                                  # stays (applied only when GNOME present)
├── nvim/                                   # stays (file.lua paths fixed)
├── packages/                               # packages_dnf typo fixed
├── tmux/                                   # stays
├── vim/                                    # stays
├── vscode/                                 # stays (install_extensions.sh generated from extensions.txt)
├── wallpapers/                             # stays
├── zsh/                                    # stays (.zshrc path fixed; opencode PATH guarded)
├── install.sh                              # refactored (new flags)
└── README.md                               # updated
```

No existing config file content is dropped. GNOME and Ghostty remain applied
on bare-Linux/SSH hosts; `install.sh` simply skips them when GNOME/dconf or
Ghostty is absent (the WSL case).

## 3. Migration strategy: same machine, destructive

Because the box is wiped, the plan locks in an **extraction-before-wipe**
phase and a **rebuild-after-Windows** phase:

- **Pre-wipe (on this Fedora box):** `git push` the repo; additionally dump
  `dconf dump / > gnome/full-dconf.ini` for completeness (optional). Cursor
  is on another machine; its extraction is non-blocking and done later via
  `cursor/EXTRACT.md`.
- **Wipe:** install Windows 11, boot, run `windows/bootstrap.ps1`.
- **Restore:** clone the repo on the Windows host
  (`$env:USERPROFILE\dev\dotfiles`) and again into `~/dotfiles` inside WSL,
  run `wsl/setup-wsl.ps1`, then `wsl/post-install.sh` inside WSL.

## 4. Cursor config scaffolding

Cursor is on another machine; the new `cursor/` dir is provisioned by
**deriving** from `vscode/` plus Cursor specifics, and a recipe replaces it
later with the real config:

- `cursor/settings.json` — derived from `vscode/settings.json` with
  Cursor-specific keys (`cursor.{ai,tab,composer}.*`, telemetry off).
- `cursor/keybindings.json` — copy of `vscode/keybindings.json` (Cursor is
  VS Code-compatible).
- `cursor/extensions.txt` — superset of `vscode/extensions.txt` with
  Cursor-side extras.
- `cursor/EXTRACT.md` — where Cursor stores config on each OS, how to run
  `cursor --list-extensions` to regenerate `extensions.txt`, and what to
  copy into the repo.
- `cursor/windows-profile.ps1` — links `cursor/*` into
  `%APPDATA%\Cursor\User` on the Windows host and installs extensions from
  `extensions.txt`.

To fix the existing anti-pattern where `vscode/install_extensions.sh` has a
hardcoded list divergent from `vscode/extensions.txt`, both editor dirs now
have their installer **generated from the txt** by
`scripts/gen-extension-installer.sh` at install/edit time.

## 5. Bug / bad-config refactors (correctness + cross-platform hardening)

| # | File | Problem | Fix |
|---|------|---------|-----|
| R1 | `packages/packages_dnf` | `gnome-tweeks` typo | `gnome-tweaks` |
| R2 | `nvim/lua/settings/file.lua` | stale macOS paths `/Users/thallys/...` | `vim.fn.expand("~/dotfiles/zsh/config")` etc. |
| R3 | `install.sh:320` | hardcoded `$HOME/dotfiles/tmux/scripts` | use `$DOTFILES_DIR/tmux/scripts` |
| R4 | `install.sh:331-336` | VS Code linking silent no-op when `~/.config/Code/User` absent | detect platform; warn clearly; link on Windows via `%APPDATA%\Code\User` |
| R5 | `vscode/install_extensions.sh` | hardcoded list drifts from `extensions.txt` | generate from `extensions.txt` |
| R6 | `install.sh` | always runs GNOME dconf even on WSL | gate on `dconf` exists **and** ($XDG_CURRENT_DESKTOP contains GNOME **or** `--gnome`) |
| R7 | `install.sh` | Ghostty add attempted in WSL | gate: skip when `--wsl` or no GUI (`$DISPLAY` + `$WAYLAND_DISPLAY` empty) |
| R8 | `install.sh:346` | unchecked `curl | bash` for `linux.toys` | gate behind `--with-toys` (default off in WSL) |
| R9 | `zsh/.zshrc` | hardcoded `~/dotfiles/...`, unguarded `~/.opencode/bin` | resolve via `$DOTFILES_DIR`; guard with `[ -d ]` |
| R10 | `fastfetch/config.jsonc` | `wm`, `de`, `theme`, `icons` empty under WSL | add `fastfetch/config.wsl.jsonc`, selected by install.sh on WSL |
| R11 | `install.sh` | `uv tool` installs + Mason overlap; `nvm install --lts` interactive | idempotent guards; WSL-skip of GUI only |
| R12 | `ghostty/` link | always links even on WSL | link only when Ghostty binary-or-Linux-desktop detected |

No behavior drift on bare Linux: `install.sh` with no flags behaves exactly
as today. New flags only *suppress* steps.

## 6. Windows host bootstrap (`windows/bootstrap.ps1`)

PowerShell 5.1+. Idempotent. Steps:

1. Enable WSL2 + Virtual Machine Platform (`dism`/`wsl --set-default-version 2`); reboot prompt if needed.
2. **winget** installs from `windows/winget-packages.txt`: Windows Terminal, Git, Cursor, VS Code, PowerToys, JetBrains Mono (or via scoop).
3. **scoop** bootstrap (`iwr | iex`), then `scoop install` from `windows/scoop-packages.txt`: ripgrep, fd, fzf, bat, eza, zoxide, delta, lazygit, yazi, just, make, less. These go on the **Windows** PATH.
4. Drop Windows Terminal `settings.json` into
   `$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`.
   Default profile = Fedora WSL distro; Kanagawa-wave color scheme (generated since WT doesn't ship it); JetBrains Mono 14; opacity 90; acrylic.
5. Apply Cursor config via `cursor/windows-profile.ps1` if Cursor installed (else skip).
6. Clone the repo to `$env:USERPROFILE\dev\dotfiles`.
7. Run `wsl/setup-wsl.ps1` (next section).

## 7. WSL Fedora bootstrap

`wsl/setup-wsl.ps1` (runs on Windows host, once):

1. Download Fedora 43 rootfs tarball (documented exact command in HOWTO).
2. `wsl --import Fedora43 C:\WSL\Fedora43 fedora-43-rootfs.tar.gz`.
3. Create default user `thallys`; drop `/etc/wsl.conf` (systemd enabled, default user) and `%USERPROFILE%\.wslconfig` (`wsl/fedora.wslconfig`) for memory/CPU/networking.
4. Hand off: `wsl -d Fedora43 -- bash -lc "..."`.

`wsl/post-install.sh` (runs inside WSL):

1. `dnf upgrade -y`; install `packages/packages_dnf`.
2. Run `./install.sh --wsl --no-flatpak` (skips GNOME, Ghostty, flatpak, linux.toys; does zsh+oh-my-zsh, tmux+TPM, lazy.nvim, nvim, vim, git, fastfetch WSL variant).
3. Install **opencode** into WSL (curl installer; the repo already adds `~/.opencode/bin` to PATH — guarded).
4. Install **Codex CLI**: `npm i -g @openai/codex` after the NVM step in install.sh; pin a version for reproducibility.
5. Optional WSLg niceties (`scripts/wsl-gui-fix.sh`): clipboard/dbus only if WSLg present; no-op otherwise.
6. Print next-steps referencing `docs/HOWTO-from-poweron.md`.

## 8. end-to-end how-to (`docs/HOWTO-from-poweron.md`)

Single numbered document from a blank machine:

1. First boot of Windows 11 — OOBE, sign in, Windows Update, hostname, display/GPU drivers.
2. Enable WSL2 — run `wsl/setup-wsl.ps1` prerequisites; reboot.
3. Clone dotfiles on Windows host.
4. Run Windows bootstrap.
5. Enter WSL, run post-install.
6. (Optional) Apply Cursor config from the other machine.
7. Sanity checks — fastfetch, nvim, tmux, `opencode`, `codex`, Cursor Remote-WSL.
8. Verification matrix.
9. Rollback / troubleshoot.

## 9. What changes vs. what stays

- **Stays:** zsh, tmux, nvim, vim, git, fastfetch, ghostty, gnome configs' content. Muscle memory transfers intact.
- **New:** `windows/`, `wsl/`, `cursor/`, `scripts/`, `docs/`, plus flags on `install.sh`.
- **Repo divergence risk:** zero to existing hosts — `install.sh` with no flags behaves exactly as today.

## 10. Out of scope (YAGNI)

- No migration of app data (Obsidian vaults, browser profiles, Bitwarden state) — synced by their own apps.
- No Windows desktop theming (no Rainmeter/ExplorerPatcher). Only Windows Terminal + Cursor get a theme.
- No AHK parity mapping of GNOME keybindings — flagged as future work.
- No DSL rewrites; configs stay shell + JSON + Lua.

## 11. Order of work

1. Refactor bugs (§5 R1–R12) — pure correctness.
2. Add `--wsl`/`--gnome`/`--with-toys` flags + GUI-skip to `install.sh`; extract `scripts/link_common.sh`.
3. Add `cursor/` scaffold + `EXTRACT.md` + gen-extension-installer.
4. Add `wsl/` (scripts + `.wslconfig` + `wsl.conf`).
5. Add `windows/` (bootstrap.ps1, winget/scoop lists, Windows Terminal settings + Kanagawa scheme).
6. Wire opencode + codex into `wsl/post-install.sh`.
7. Write `docs/HOWTO-from-poweron.md`.
8. Update top-level `README.md`.
9. Verify: `shellcheck install.sh`, lua syntax check nvim, sanity-check refactor.