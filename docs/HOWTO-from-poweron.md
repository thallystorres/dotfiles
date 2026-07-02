# How-to: from first power-up to a fully working Windows 11 + Fedora WSL desktop

This is the end-to-end guide for rebuilding your environment on a freshly
wiped machine using the dotfiles repo. It assumes you are starting from a
blank Windows 11 install on the **same hardware** that previously ran
Fedora 43.

> **Before you wipe the Fedora box:** push the dotfiles repo
> (`git push`) so the latest configs are on GitHub. Optionally dump the
> full GNOME dconf: `dconf dump / > gnome/full-dconf.ini` and commit it
> for reference. Cursor config lives on **another** machine; it's
> extracted later via `cursor/EXTRACT.md` and is **not** a blocker.

---

## Step 1 — First boot of Windows 11

1. Complete the OOBE (region, keyboard, account, PIN). Skip Edge/Microsoft
   365 offers.
2. Run **Windows Update** to completion (Settings → Windows Update →
   Check for updates). Reboot as many times as it asks.
3. Set the hostname: Settings → System → About → "Rename this PC"
   (e.g. `thallys-win`). Reboot.
4. Install your **display / GPU drivers** from the manufacturer site
   (NVIDIA/AMD/Intel) or via Windows Update "Optional updates".
5. (Recommended) Sign into the Microsoft Store and pin Windows Terminal so
   it's available immediately.

## Step 2 — Get the dotfiles repo onto the Windows host

Open **PowerShell** (Win+X → Terminal → PowerShell) and:

```powershell
mkdir $env:USERPROFILE\dev -Force
cd $env:USERPROFILE\dev
git clone https://github.com/thallystorres/dotfiles.git
cd dotfiles
```

> If `git` is missing, run `winget install Git.Git` first, reopen the
> terminal, then retry.

## Step 3 — Run the Windows bootstrap

From the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File windows\bootstrap.ps1
```

What this does (full detail in `windows/INSTALL-windows.md`):

- Enables WSL2 + Virtual Machine Platform (**will reboot once** if needed).
- Installs apps via winget from `windows/winget-packages.txt`
  (Windows Terminal, Git, VS Code, PowerToys, Zoom, JetBrains Toolbox,
  Bitwarden).
- Installs scoop and CLI tools from `windows/scoop-packages.txt`
  (`bat`, `fd`, `fzf`, `eza`, `ripgrep`, `delta`, `lazygit`, `yazi`,
  `fastfetch`, …) on the Windows PATH.
- Stages `windows/windows-terminal/settings.json` (Kanagawa Wave scheme,
  default profile = Fedora WSL).
- Applies Cursor config via `cursor/windows-profile.ps1` **if Cursor is
  installed** — see Step 6.
- Installs AutoHotkey and registers `windows/ahk/gnome-keybindings.ahk` to
  run at login so **your GNOME keybindings work on Windows** (see
  "GNOME keybindings" below).
- Symlinks the PowerShell profile.
- Hands off to `wsl/setup-wsl.ps1` (next step).

### GNOME keybindings on Windows

Every binding from `gnome/keybindings.ini` is replicated by
`windows/ahk/gnome-keybindings.ahk`:

| GNOME            | GNOME action          | Windows action                          |
|------------------|-----------------------|-----------------------------------------|
| `Super+w`        | close                 | `Alt+F4`                                |
| `Super+k`        | maximize              | `Win+Up`                                |
| `Super+j`        | unmaximize            | `Win+Down`                              |
| `Super+d`        | minimize              | `Win+Down`                              |
| `Super+h`        | tile left             | `Win+Left`                              |
| `Super+l`        | tile right            | `Win+Right`  ⚠ needs enable-super-l     |
| `Shift+Super+h`  | move monitor left     | `Win+Shift+Left`                        |
| `Shift+Super+l`  | move monitor right    | `Win+Shift+Right`                        |
| `Shift+Super+j`  | move monitor down     | `Win+Shift+Down`                        |
| `Shift+Super+k`  | move monitor up       | `Win+Shift+Up`                          |
| `Shift+Super+s`  | screenshot UI          | `Win+Shift+S` (Snipping Tool)           |
| `Super+q`        | lock screen           | `LockWorkStation()` API                 |
| `Super+Enter`    | launch terminal        | Windows Terminal                        |

**One-off admin step** (only needed for `Super+l` — Windows reserves `Win+L`
for lock):

```powershell
powershell -ExecutionPolicy Bypass -File windows\enable-super-l.ps1
```

Reboot after. `Super+q` keeps working as the lock key regardless — it calls
the Windows lock API directly, not `Win+L`. To revert:
`…\enable-super-l.ps1 -Revert`.

> The AHK script starts at every login via a shortcut in the Startup
> folder (created by `bootstrap.ps1`). To apply bindings in the current
> session right after install, run `windows\ahk\gnome-keybindings.ahk`
> (AutoHotkey is installed by winget during bootstrap).

**If it reboots for WSL features**, log back in, reopen PowerShell in the
repo, and rerun the same command (everything is idempotent). Add
`-SkipWsl` if you'd rather run the WSL step manually.

## Step 4 — Create the Fedora 43 WSL distro

`wsl/setup-wsl.ps1` (called by bootstrap unless `-SkipWsl`):

1. Downloads the Fedora 43 rootfs (pulls `fedora:43` via Docker and exports
   it; install Docker Desktop first if you don't have it, or download a
   Fedora WSL rootfs tarball manually and place it at the path printed by
   the script).
2. `wsl --import Fedora43 C:\WSL\Fedora43 <rootfs.tar.gz>`.
3. Creates user `thallys`, drops `/etc/wsl.conf` (systemd enabled, default
   user), copies `wsl/fedora.wslconfig` to `%USERPROFILE%\.wslconfig`, and
   `wsl --shutdown`.
4. Clones the dotfiles repo into the WSL home and runs
   `wsl/post-install.sh`.

> **No Docker?** Alternatively grab a community Fedora WSL build
> (e.g. from `https://github.com/fedora-llvm/wsl` or the Fedora Cloud
> image) and import it with `wsl --import Fedora43 C:\WSL\Fedora43
> fedora-rootfs.tar`. Then rerun `wsl\setup-wsl.ps1`; it skips the import
> if the distro already exists.

## Step 5 — Inside WSL: the post-install script

`wsl/post-install.sh` runs **inside Fedora WSL** (setup-wsl.ps1 invokes it
via `wsl -d Fedora43`):

1. `dnf upgrade -y` and ensures the `wheel` group can sudo without password.
2. Runs `install.sh --wsl --no-packages` — installs zsh + Oh My Zsh,
   lazy.nvim, TPM, pyenv, uv, NVM + Node LTS, and symlinks all configs
   (`zsh`, `nvim`, `tmux`, `vim`, `git`, fastfetch WSL variant). It
   **skips** GNOME, Ghostty, flatpak, and linux.toys (those are
   bare-Linux-only).
3. Installs **opencode** via `https://opencode.ai/install` into `~/.opencode/bin` (already on PATH via the zshrc).
4. Installs the **OpenAI Codex CLI** via `npm i -g @openai/codex` (after loading NVM).

You can rerun it anytime:

```bash
sudo bash ~/dotfiles/wsl/post-install.sh --user thallys
```

## Step 6 — Cursor (optional, do this from your other machine first)

Cursor is **not** on winget. To install and configure it:

1. Download the installer from <https://cursor.com/download> and run it.
2. **On your other machine** (where Cursor already has the real config),
   follow `cursor/EXTRACT.md`: dump
   `cursor --list-extensions > extensions.txt`, copy `settings.json` and
   `keybindings.json` from the OS-specific User dir, and overwrite
   `cursor/` in the repo. Commit + push.
3. Back on the Windows host, pull the repo and run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File cursor\windows-profile.ps1
   ```

   This links `cursor/settings.json` + `cursor/keybindings.json` into
   `%APPDATA%\Cursor\User` and installs every extension in
   `cursor/extensions.txt`.

   > If you skipped extraction, the repo's derived `cursor/` config
   > (based on `vscode/` + Cursor-specific keys) is a working default.

4. In Cursor: install the **"WSL" extension** (`ms-vscode-remote.remote-wsl`),
   then `Ctrl+Shift+P → "WSL: Open Folder in WSL…" → ~/dotfiles` (or your
   project). Cursor now runs natively on Windows but edits files in WSL.

## Step 7 — Sanity checks

| Check | Expected | Command |
|------|----------|---------|
| WSL distro | `Fedora43` running | `wsl -l -v` |
| Shell in WSL | zsh with omtheme prompt | `wsl -d Fedora43` then look at prompt |
| fastfetch | Kanagawa-ish, no `wm`/`de` rows | `fastfetch` |
| Neovim | Lazy.nvim dashboard / opens | `nvim` |
| Tmux | green status bar, `Ctrl+a` prefix | `tmux` |
| opencode | version banner | `opencode --version` |
| codex | version banner | `codex --version` |
| Windows Terminal | Kanagawa Wave scheme | open it — default profile auto-launches Fedora WSL |
| GNOME keybindings | `Super+w` closes the active window | focus any window, press `Win+w` |
| AHK at login | `AutoHotkey` is running on boot | Task Manager → Startup tab, or `gnome-keybindings.lnk` in `Startup` |
| Cursor | opens, Remote-WSL works | Cursor → open `\\wsl$\Fedora43\home\thallys` |

## Step 8 — Verification matrix (one-liner)

Inside WSL:

```bash
fastfetch && nvim --version | head -1 && tmux -V && \
  opencode --version && codex --version && echo OK
```

On Windows host (PowerShell):

```powershell
wsl -l -v; winget --version; scoop --version; bat --version
```

## Step 9 — Rollback / troubleshooting

- **WSL distro misbehaving** — unregister and reimport:
  `wsl --unregister Fedora43`, then rerun `wsl/setup-wsl.ps1`.
- **`chsh` failed in WSL** — `echo $(which zsh) | sudo tee -a /etc/shells`,
  then `sudo chsh -s $(which zsh) $USER`.
- **Windows Terminal doesn't show Kanagawa scheme** — start Windows
  Terminal once before running bootstrap so it creates its `LocalState`
  dir; rerun `windows\bootstrap.ps1` step 4 (or copy
  `windows\windows-terminal\settings.json` manually).
- **Font not applying** — confirm JetBrains Mono installed
  (`Get-ChildItem C:\Windows\Fonts | Where-Object Name -like '*JetBrains*'`);
  re-run `winget install JetBrains.JetBrainsMono`.
- **Cursor config not applied** — run Cursor once first (creates
  `%APPDATA%\Cursor\User`), then re-run `cursor\windows-profile.ps1`.
- **opencode not found** — ensure `~/.opencode/bin` exists; the zshrc only
  prepends it when it does. Re-run `wsl/post-install.sh`.
- **`npm` missing when installing codex** — install.sh installs NVM; reopen
  the shell or `source ~/.nvm/nvm.sh` first.
- **Idempotent reruns** — every script checks before acting; rerun
  `windows\bootstrap.ps1`, `wsl\setup-wsl.ps1`, or `wsl/post-install.sh`
  as many times as needed.

## Reference

- Spec: `docs/superpowers/specs/2026-07-01-windows11-wsl-migration-design.md`
- Windows host: `windows/INSTALL-windows.md`
- WSL guest: `wsl/post-install.sh` (header comment)
- Cursor extraction: `cursor/EXTRACT.md`
- Bug list fixed by this migration: §5 of the spec.