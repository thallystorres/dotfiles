# 🔧 Dotfiles

Welcome to my personal dotfiles repository! This collection features my "ricing"
configuration for a highly productive Linux environment, focusing on aesthetics
and efficiency.

These dotfiles are designed to work seamlessly on **Fedora (DNF)** and
**Debian/Ubuntu (APT)** based systems, on **Windows 11** (host), and on
**Fedora 43 inside WSL2** (guest). The same tree drives all three; `install.sh`
auto-detects WSL and skips GNOME/Ghostty/flatpak there. See
[`docs/HOWTO-from-poweron.md`](docs/HOWTO-from-poweron.md) for the full
Windows 11 + WSL rebuild guide.

## ✨ Features

- **Terminal Emulator:** [Ghostty](https://ghostty.org/) configured with the
  **Kanagawa Wave** theme and `JetBrains Mono` font (bare Linux); **Windows
  Terminal** with the same Kanagawa palette on Windows 11 (see `windows/`).
- **Shell:** Zsh with [Oh My Zsh](https://ohmyz.sh/), custom `omtheme`, and
  plugins (autosuggestions, syntax-highlighting).
- **Editor:** Neovim setup powered by **Lazy.nvim**, featuring:
  - LSP support (Python, Lua, Rust, Web, Bash) via Mason.
  - Formatting with Conform (Prettier, Stylua, Ruff).
  - File navigation with Telescope and Neo-tree.
  - Session management with Auto-Session.
- **Multiplexer:** Tmux configured with `Ctrl+a` prefix, popup windows for quick
  tools, and session resurrection.
- **Window Manager:** GNOME custom keybindings and settings (bare Linux only).
- **AOSS tooling:** opencode and the OpenAI Codex CLI wired into the WSL guest.
- **Extras:** Fastfetch config, VSCode + Cursor settings, Windows 11 host
  bootstrap, and automated installation scripts.

## 🖼️ Previews

## 🚀 Installation

The `install.sh` script handles everything: package installation, symlinking,
and configuration.

1.  **Clone the repository:**

    ```bash
    git clone [https://github.com/thallystorres/dotfiles.git](https://github.com/thallystorres/dotfiles.git)
    cd dotfiles
    ```

2.  **Run the installer:**
    ```bash
    chmod +x install.sh
    ./install.sh                 # bare Linux (DNF/APT + GNOME + Ghostty + flatpak)
    ./install.sh --wsl           # inside WSL: skips GNOME/Ghostty/flatpak/toys
    ```

### Windows 11 + WSL

From a freshly-installed Windows 11 box:

```powershell
git clone https://github.com/thallystorres/dotfiles.git $env:USERPROFILE\dev\dotfiles
cd $env:USERPROFILE\dev\dotfiles
powershell -ExecutionPolicy Bypass -File windows\bootstrap.ps1
```

`bootstrap.ps1` enables WSL2, installs apps via winget + scoop, stages the
Windows Terminal Kanagawa config, applies the Cursor config, then hands off
to `wsl/setup-wsl.ps1` (creates the Fedora 43 WSL distro and runs
`wsl/post-install.sh`, which wires **opencode** and the **Codex CLI** into
WSL). Full details: [`docs/HOWTO-from-poweron.md`](docs/HOWTO-from-poweron.md).

### `install.sh` flags

| Flag | Effect |
|------|--------|
| `--wsl` | WSL guest mode: skip GNOME, Ghostty, flatpak, linux.toys |
| `--gnome` | Force the GNOME dconf load even if `XDG_CURRENT_DESKTOP` isn't GNOME |
| `--with-toys` | Run the `linux.toys` installer (default-on on bare Linux) |
| `--no-flatpak` | Skip the flatpak step |
| `--no-packages` | Skip the `dnf`/`apt` package install (let a wrapper handle it) |

## ⌨️ Keybindings

### Tmux

| Keybinding     | Action                                    |
| :------------- | :---------------------------------------- |
| `Ctrl + a`     | **Prefix key** (remapped from `Ctrl + b`) |
| `Prefix + r`   | Reload configuration                      |
| `Prefix + [`   | Enter copy mode (Vim motions enabled)     |
| `Prefix + C-l` | List windows with FZF                     |
| `Prefix + C-n` | Open Scratchpad notes (Popup)             |
| `Prefix + C-p` | Open Python REPL (Popup)                  |
| `Prefix + C-h` | Open Htop (Popup)                         |
| `Prefix + C-w` | Toggle floating terminal session          |

### Neovim

| Keybinding      | Action                                |
| :-------------- | :------------------------------------ |
| `Space`         | **Leader key**                        |
| `jj`            | Exit Insert Mode (alternative to Esc) |
| `Ctrl + n`      | Toggle Neo-tree filesystem            |
| `<Leader> + ff` | Find files (Telescope)                |
| `<Leader> + fg` | Live Grep (Telescope)                 |
| `<Leader> + f`  | Format file (Conform)                 |
| `<Leader> + w`  | Save file                             |
| `<Leader> + q`  | Quit                                  |
| `gl`            | Open diagnostic float                 |

## 📂 Structure

- `install.sh`: Main installation entry point (flags: `--wsl`, `--gnome`, `--with-toys`, `--no-flatpak`, `--no-packages`).
- `zsh/`: Zsh configuration, aliases, and custom theme.
- `nvim/`: Neovim Lua configuration.
- `tmux/`: Tmux configuration and helper scripts.
- `ghostty/`: Ghostty terminal config and themes (bare Linux only).
- `vim/`: Classic Vim config (vim-plug).
- `fastfetch/`: Fastfetch config + WSL variant (`config.wsl.jsonc`).
- `packages/`: Lists of packages for `dnf`, `apt`, `brew`, and `flatpak`.
- `vscode/`: VSCode settings, keybindings, and extensions list.
- `cursor/`: Cursor (VS Code fork) settings, keybindings, extensions, Windows profile, and extraction recipe (`EXTRACT.md`).
- `git/`: Global git config (delta pager, nvim editor).
- `gnome/`: GNOME dconf dumps for keybindings (bare Linux only).
- `windows/`: Windows host bootstrap (`bootstrap.ps1`), winget + scoop package lists, Windows Terminal settings with Kanagawa scheme, PowerShell profile.
- `wsl/`: WSL Fedora 43 setup (`setup-wsl.ps1`), in-distro `post-install.sh` (wires opencode + Codex CLI), `wsl.conf`, `.wslconfig`.
- `scripts/`: Helper scripts (`gen-extension-installer.sh` regenerates editor extension installers from `extensions.txt`).
- `docs/`: `HOWTO-from-poweron.md` end-to-end guide + design specs.

## 📦 Tooling

- **Package Managers:** Homebrew, DNF/APT, Flatpak.
- **Languages:** Python (Pyenv + UV), Node.js (NVM), Lua, Rust.
- **CLI Tools:** `bat`, `eza`, `zoxide`, `fzf`, `ripgrep`, `yazi`.

## 👏 Credits

Special thanks to the content creators who inspired this configuration:

- **Luiz Otávio Miranda Figueiredo:** [GitHub](https://github.com/luizomf) |
  [YouTube](https://www.youtube.com/@otaviomiranda)
- **TypeCraft:** [GitHub](https://github.com/typecraft-dev) |
  [YouTube](https://youtube.com/@typecraft_dev)
- **Psygreg:** [GitHub](https://github.com/psygreg) |
  [YouTube](https://www.youtube.com/@psygreg)
