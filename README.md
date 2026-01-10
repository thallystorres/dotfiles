# 🔧 Dotfiles

Welcome to my personal dotfiles repository! This collection features my "ricing"
configuration for a highly productive Linux environment, focusing on aesthetics
and efficiency.

These dotfiles are designed to work seamlessly on **Fedora (DNF)** and
**Debian/Ubuntu (APT)** based systems.

## ✨ Features

- **Terminal Emulator:** [Ghostty](https://ghostty.org/) configured with the
  **Kanagawa Wave** theme and `JetBrains Mono` font.
- **Shell:** Zsh with [Oh My Zsh](https://ohmyz.sh/), custom `omtheme`, and
  plugins (autosuggestions, syntax-highlighting).
- **Editor:** Neovim setup powered by **Lazy.nvim**, featuring:
  - LSP support (Python, Lua, Rust, Web, Bash) via Mason.
  - Formatting with Conform (Prettier, Stylua, Ruff).
  - File navigation with Telescope and Neo-tree.
  - Session management with Auto-Session.
- **Multiplexer:** Tmux configured with `Ctrl+a` prefix, popup windows for quick
  tools, and session resurrection.
- **Window Manager:** GNOME custom keybindings and settings.
- **Extras:** Fastfetch config, VSCode settings, and automated installation
  scripts.

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
    ./install.sh
    ```

> **Note:** The script will detect your package manager (`dnf` or `apt`),
> install necessary dependencies (zsh, neovim, tmux, fonts, etc.), install
> Homebrew & Flatpaks, and link configuration files to your `$HOME` directory.

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

- `install.sh`: Main installation entry point.
- `zsh/`: Zsh configuration, aliases, and custom theme.
- `nvim/`: Neovim Lua configuration.
- `tmux/`: Tmux configuration and helper scripts.
- `ghostty/`: Ghostty terminal config and themes.
- `packages/`: Lists of packages for `dnf`, `apt`, `brew`, and `flatpak`.
- `vscode/`: VSCode settings and keybindings.
- `gnome/`: GNOME dconf dumps for keybindings.

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
