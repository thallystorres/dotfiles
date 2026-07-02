#!/bin/bash
# =============================================================================
# dotfiles install.sh
# -----------------------------------------------------------------------------
# Symlinks all configs into $HOME and installs the underlying tools.
#
# Behavior:
#   * No flags            -> bare-Linux path (DNF/APT + GNOME + Ghostty + flatpak)
#                            Identical to the historical behavior.
#   * --wsl              -> WSL guest path: skips GNOME, Ghostty, flatpak,
#                            linux.toys (even if dconf/ghostty happen to exist).
#   * --no-flatpak       -> skip the flatpak step (anywhere).
#   * --gnome            -> force the GNOME dconf load even if $XDG_CURRENT_DESKTOP
#                            doesn't advertise GNOME.
#   * --with-toys        -> run the linux.toys installer (off by default in WSL,
#                            on by default bare-Linux for backward compat).
#   * --no-packages      -> skip the system package install (useful when running
#                            inside post-install.sh which already dnf'd).
#
# All flags are purely *suppressive*; nothing new happens on bare Linux without
# them.  See docs/superpowers/specs/2026-07-01-windows11-wsl-migration-design.md.
# =============================================================================

set -o pipefail

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PACKAGES_DIR="$DOTFILES_DIR/packages"
LOG_FILE="$DOTFILES_DIR/install.log"

# ---- flag parsing ----------------------------------------------------------
MODE_WSL=0
FORCE_GNOME=0
WITH_TOYS=0          # default off; we set to 1 below for bare-Linux default
SKIP_FLATPAK=0
SKIP_PACKAGES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --wsl)          MODE_WSL=1; WITH_TOYS=0; ;;
    --gnome)        FORCE_GNOME=1 ;;
    --with-toys)    WITH_TOYS=1 ;;
    --no-flatpak)   SKIP_FLATPAK=1 ;;
    --no-packages)  SKIP_PACKAGES=1 ;;
    -h|--help)
      sed -n '2,25p' "$0"
      exit 0 ;;
    *) logerror "Unknown flag: $1"; exit 2 ;;
  esac
  shift
done

# bare-Linux default: keep toys on (historical behavior) unless --wsl
[ "$MODE_WSL" -eq 1 ] || WITH_TOYS=1

# ---- GUI detection --------------------------------------------------------
HAS_DISPLAY=$([ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] && echo 1 || echo 0)
# In WSL, $WAYLAND_DISPLAY may be set by WSLg but Ghostty/GNOME are still N/A.
INSIDE_WSL=0
if grep -qaE '(microsoft|WSL)' /proc/version 2>/dev/null; then INSIDE_WSL=1; fi
[ "$MODE_WSL" -eq 0 ] || INSIDE_WSL=1

# ---- log helpers -----------------------------------------------------------
loginfo()    { printf "🔵 \033[1;34m%s\033[0m\n" "$1"; }
logsuccess() { printf "🟢 \033[1;32m%s\033[0m\n" "$1"; }
logerror()   { printf "🔴 \033[1;31m%s\033[0m\n" "$1"; }
logwarn()    { printf "🟡 \033[1;33m%s\033[0m\n" "$1"; }

# ==========================================
# 1. Package Manager Detection
# ==========================================

PACKAGER=""
INSTALL_CMD=""
UPDATE_CMD=""

if command -v dnf >/dev/null 2>&1; then
  loginfo "RPM based system detected (Fedora/RHEL)"
  PACKAGER="dnf"
  INSTALL_CMD="sudo dnf install -y"
  UPDATE_CMD="sudo dnf upgrade --refresh -y"
elif command -v apt >/dev/null 2>&1; then
  loginfo "Debian based system detected (Ubuntu/Pop/Mint)."
  PACKAGER="apt"
  INSTALL_CMD="sudo apt install -y"
  UPDATE_CMD="sudo apt update && sudo apt upgrade -y"
else
  logerror "Package manager not supported. Exiting script."
  exit 1
fi

# ==========================================
# 2. System Update and Packages
# ==========================================

if [ "$SKIP_PACKAGES" -eq 1 ]; then
  loginfo "Skipping system package install (--no-packages)."
else
  loginfo "Updating system..."
  eval $UPDATE_CMD

  if [ "$PACKAGER" == "dnf" ]; then
    PACKAGE_LIST="$PACKAGES_DIR/packages_dnf"
  else
    PACKAGE_LIST="$PACKAGES_DIR/packages_apt"
  fi

  loginfo "Installing packages listed in $(basename "$PACKAGE_LIST")..."
  if [ -f "$PACKAGE_LIST" ]; then
    grep -vE '^\s*$' "$PACKAGE_LIST" | while read -r package; do
      loginfo "Trying to install: $package"
      $INSTALL_CMD "$package" 2>> "$LOG_FILE"
      if [ $? -eq 0 ]; then
        logsuccess "$package installed."
      else
        logwarn "Failed to install $package. Verify log."
      fi
    done
  else
    logerror "Package file not found at $PACKAGE_LIST"
  fi
fi

# ==========================================
# 3. Homebrew (Brewfile)
# ==========================================

if [ -f "$PACKAGES_DIR/Brewfile" ]; then
  loginfo "Checking Homebrew..."
  if ! command -v brew >/dev/null 2>&1; then
    loginfo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
  fi
  loginfo "Installing Brewfile packages..."
  brew bundle --file="$PACKAGES_DIR/Brewfile"
else
  logwarn "Brewfile not found. Skipping step."
fi

# ==========================================
# 4. Flatpaks  (skipped under --wsl / --no-flatpak / no GUI)
# ==========================================

if [ "$SKIP_FLATPAK" -eq 1 ] || [ "$INSIDE_WSL" -eq 1 ] || [ "$HAS_DISPLAY" -eq 0 ]; then
  loginfo "Skipping Flatpak step (WSL or --no-flatpak or no GUI)."
else
  if [ -f "$PACKAGES_DIR/flatpaks.txt" ]; then
    loginfo "Checking Flatpak..."
    if ! command -v flatpak >/dev/null 2>&1; then
      $INSTALL_CMD flatpak
    fi
    loginfo "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    loginfo "Installing Flatpaks..."
    if [ -s "$PACKAGES_DIR/flatpaks.txt" ]; then
        xargs -a "$PACKAGES_DIR/flatpaks.txt" flatpak install -y
    fi
  else
    logwarn "Flatpak list not found."
  fi
fi

# ==========================================
# 5. Ghostty config  (skipped under --wsl / no GUI)
# ==========================================

install_ghostty() {
  if [ "$INSIDE_WSL" -eq 1 ] || [ "$HAS_DISPLAY" -eq 0 ]; then
    loginfo "Skipping Ghostty install (WSL / no GUI). Config stays in repo for Linux/SSH use."
    return
  fi
  if command -v ghostty >/dev/null 2>&1; then
    loginfo "Ghostty already installed..."
    return
  fi
  loginfo "Installing Ghostty..."
  if [ "$PACKAGER" == "dnf" ]; then
    loginfo "Setting COPR for Ghostty (Fedora)..."
    sudo dnf copr enable -y pgdev/ghostty
    sudo dnf install -y ghostty
  elif [ "$PACKAGER" == "apt" ]; then
    loginfo "Setting Ghostty repository (Debian based)..."
    KEYRING="/usr/share/keyrings/ghostty.gpg"
    if [ ! -f "$KEYRING" ]; then
      loginfo "Downloading GPG Key..."
      curl -fsSL https://repo.ghostty.org/apt/gpg.key | sudo gpg --dearmor -o "$KEYRING"
    fi
    LIST_FILE="/etc/apt/sources.list.d/ghostty.list"
    if [ ! -f "$LIST_FILE" ]; then
      loginfo "Adding source list..."
      echo "deb [signed-by=$KEYRING] https://repo.ghostty.org/apt stable main" | sudo tee "$LIST_FILE" > /dev/null
    fi
    sudo apt update
    sudo apt install -y ghostty
  fi
}
install_ghostty

# ==========================================
# 6. Zsh config
# ==========================================

if command -v zsh >/dev/null; then
  if [ "$SHELL" != "$(which zsh)" ]; then
    loginfo "Setting ZSH as default shell..."
    # In WSL, chsh may require /etc/shells entry; warn on failure.
    if ! sudo chsh -s "$(which zsh)" "$USER" 2>>"$LOG_FILE"; then
      logwarn "chsh failed (WSL may need 'echo \$(which zsh) >> /etc/shells' first)."
    fi
  fi
fi

loginfo "Settings Zsh and Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh/" ]; then
  loginfo "Installing Oh My Zsh..."
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  loginfo "Oh My Zsh already installed."
fi
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
loginfo "🔌 Adding Zsh plugins..."
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
fi
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
fi

# ==========================================
# 7. Lazy.nvim config
# ==========================================

loginfo "🐘 Setting up NeoVim and LazyVim"
LAZY_PATH="$HOME/.local/share/nvim/lazy/lazy.nvim"
if [ ! -d "$LAZY_PATH" ]; then
  loginfo "Adding Neovim plugin manager lazy.vim"
  git clone https://github.com/folke/lazy.nvim.git --filter=blob:none "$LAZY_PATH"
fi

# ==========================================
# 8. Tmux Plugin Manager config
# ==========================================

loginfo "🔄 Installing TPM for tmux..."
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# ==========================================
# 9. Language package managers
# ==========================================

if ! command -v pyenv &> /dev/null; then
  loginfo "Installing Pyenv..."
  rm -Rf "${HOME}/.pyenv"
  curl -fsSL https://pyenv.run | bash
else
  loginfo "Pyenv already installed..."
fi

if ! command -v uv &> /dev/null; then
  loginfo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
else
  loginfo "UV already installed..."
fi

if ! command -v nvm &> /dev/null; then
  loginfo "Installing NVM..."
  rm -Rf "${HOME}/.nvm"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
else
  loginfo "NVM already installed..."
fi

# Load NVM for this session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

if command -v nvm >/dev/null 2>&1; then
    loginfo "Installing Node LTS via NVM..."
    nvm install --lts
    nvm use --lts
    npm i -g prettier
fi

# Load Pyenv for this session
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
  loginfo "Installing Python 3.13..."
  if ! pyenv versions | grep -q "3.13.0"; then
      pyenv install 3.13.0
  fi
  pyenv global 3.13.0
fi

if command -v uv 1>/dev/null 2>&1; then
    uv tool install pyright
    uv tool install ruff
fi

# ==========================================
# 10. Dotfiles Links
# ==========================================

loginfo "Creating symlinks (Overwriting existing files)..."

# Function to link files WITHOUT backup (Overwrites)
link_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]; then
    loginfo "Already linked: $dest"
    return
  fi

  if [ -e "$dest" ] || [ -h "$dest" ]; then
    logwarn "Removing existing file: $dest"
    rm -rf "$dest"
  fi

  ln -s "$src" "$dest"
  logsuccess "Linked: $src -> $dest"
}

# ZSH
link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"

# Specific Theme linking (Fixed path)
rm -Rf "$ZSH_CUSTOM/themes/omtheme.zsh-theme"
ln -sf "$DOTFILES_DIR/zsh/config/omtheme.zsh-theme" "$ZSH_CUSTOM/themes/omtheme.zsh-theme"

# Git
link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# Tmux
link_file "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
# Ensure scripts dir exists (path derived from $DOTFILES_DIR, not hardcoded $HOME)
mkdir -p "$DOTFILES_DIR/tmux/scripts"

# Neovim
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# Ghostty  (only when it makes sense to apply)
if [ "$INSIDE_WSL" -eq 0 ] && [ "$HAS_DISPLAY" -eq 1 ]; then
  link_file "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"
else
  loginfo "Skipping Ghostty link (WSL / no GUI). Config remains in repo."
fi

# Fastfetch  (WSL variant when --wsl)
if [ "$INSIDE_WSL" -eq 1 ] && [ -f "$DOTFILES_DIR/fastfetch/config.wsl.jsonc" ]; then
  # Link whole dir, then swap the active config to the WSL variant
  link_file "$DOTFILES_DIR/fastfetch" "$HOME/.config/fastfetch"
  ln -sf "$DOTFILES_DIR/fastfetch/config.wsl.jsonc" "$HOME/.config/fastfetch/config.jsonc"
  loginfo "Linked WSL fastfetch variant."
else
  link_file "$DOTFILES_DIR/fastfetch" "$HOME/.config/fastfetch"
fi

# VSCode (Linux / WSL)
if [ -d "$HOME/.config/Code/User" ]; then
    link_file "$DOTFILES_DIR/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
    link_file "$DOTFILES_DIR/vscode/keybindings.json" "$HOME/.config/Code/User/keybindings.json"
    if [ -f "$DOTFILES_DIR/vscode/install_extensions.sh" ]; then
        bash "$DOTFILES_DIR/vscode/install_extensions.sh"
    fi
else
    loginfo "VS Code User dir not found (skipping Linux link). Configure via the Windows host or Cursor profile."
fi

# Vim
link_file "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"

# ==========================================
# 11. Linux Toys (opt-in, off in WSL)
# ==========================================

if [ "$WITH_TOYS" -eq 1 ] && [ "$INSIDE_WSL" -eq 0 ]; then
  loginfo "Installing Linux Toys..."
  curl -fsSL https://linux.toys/install.sh | bash
else
  loginfo "Skipping Linux Toys (use --with-toys to enable)."
fi

# ==========================================
# 12. GNOME keybindings (only when GNOME present, or --gnome)
# ==========================================

if [ "$INSIDE_WSL" -eq 1 ] && [ "$FORCE_GNOME" -ne 1 ]; then
  loginfo "Skipping GNOME keybindings (WSL)."
else
  if command -v dconf >/dev/null 2>&1; then
    GNOME_DETECTED=0
    case "${XDG_CURRENT_DESKTOP:-}" in
      *GNOME*|*gnome*) GNOME_DETECTED=1 ;;
    esac
    if [ "$FORCE_GNOME" -eq 1 ] || [ "$GNOME_DETECTED" -eq 1 ]; then
      KEYS_CONFIG="$DOTFILES_DIR/gnome/keybindings.ini"
      if [ -f "$KEYS_CONFIG" ]; then
        loginfo "Restoring GNOME keybindings..."
        dconf load /org/gnome/ < "$KEYS_CONFIG"
        if [ $? -eq 0 ]; then
            logsuccess "Keybindings restored!"
        else
            logwarn "Failed to restore keybindings. Check if file format matches dconf dump."
        fi
      else
          logwarn "Keybindings file not found at $KEYS_CONFIG"
      fi
    else
      loginfo "GNOME not current desktop (XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-<unset>}). Use --gnome to force."
    fi
  else
    logwarn "dconf command not found. Skipping GNOME setup."
  fi
fi

# ==========================================
# 13. Finalization
# ==========================================

loginfo "Installation complete! Restart your terminal or log out."
[ "$INSIDE_WSL" -eq 1 ] && loginfo "You are in WSL: also run wsl/post-install.sh for opencode + codex."