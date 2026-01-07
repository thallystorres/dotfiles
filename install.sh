#!/bin/bash

# Initial config and log functions

DOTFILES_DIR="$HOME/dotfiles"
# Adjust this path if your folder is named 'dotfiles/packages'
PACKAGES_DIR="$DOTFILES_DIR/packages" 
LOG_FILE="$DOTFILES_DIR/install.log"

loginfo() {
  local BLUE='\033[1;34m'
  local RESET='\033[0m'
  printf "🔵 ${BLUE}%s${RESET}\n" "$1"
}

logsuccess() {
  local GREEN='\033[1;32m'
  local RESET='\033[0m'
  printf "🟢 ${GREEN}%s${RESET}\n" "$1"
}

logerror() {
  local RED='\033[1;31m'
  local RESET='\033[0m'
  printf "🔴 ${RED}%s${RESET}\n" "$1"
}

logwarn() {
  local YELLOW='\033[1;33m'
  local RESET='\033[0m'
  printf "🟡 ${YELLOW}%s${RESET}\n" "$1"
}

# ==========================================
# 1. Package Manager Detection
# ==========================================

PACKAGER=""
INSTALL_CMD=""
UPDATE_CMD=""
GHOSTTY_CMD=""

if command -v dnf >/dev/null 2>&1; then
  loginfo "RPM based system detected (Fedora/RHEL)"
  PACKAGER="dnf"
  INSTALL_CMD="sudo dnf install -y"
  UPDATE_CMD="sudo dnf upgrade --refresh -y"
  GHOSTTY_CMD="sudo bash -c 'loginfo Installing Ghostty with dnf && dnf install -y dnf-plugins-core && dnf copr enable -y pgdev/ghostty && dnf install -y ghostty'"
elif command -v apt >/dev/null 2>&1; then
  loginfo "Debian based system detected (Ubuntu/Pop/Mint)."
  PACKAGER="apt"
  INSTALL_CMD="sudo apt install -y"
  UPDATE_CMD="sudo apt update && sudo apt upgrade -y"
  GHOSTTY_CMD="sudo bash -c 'apt update && apt install -y curl ca-certificates gnupg && curl -fsSL https://repo.ghostty.org/apt/gpg.key | gpg --dearmor -o /usr/share/keyrings/ghostty.gpg && echo "deb [signed-by=/usr/share/keyrings/ghostty.gpg] https://repo.ghostty.org/apt stable main" > /etc/apt/sources.list.d/ghostty.list && apt update && apt install -y ghostty'"
else
  logerror "Package manager not supported. Exiting script."
  exit 1
fi

# ==========================================
# 2. System Update and Packages
# ==========================================

loginfo "Updating system..."
eval $UPDATE_CMD

if [ "$PACKAGER" == "dnf" ]; then
  PACKAGE_LIST="$PACKAGES_DIR/packages_dnf"
else
  PACKAGE_LIST="$PACKAGES_DIR/packages_apt"
fi

loginfo "Installing packages listed in $(basename "$PACKAGE_LIST")..."
if [ -f "$PACKAGE_LIST" ]; then
  # Reads the file ignoring empty lines
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

# ==========================================
# 3. Homebrew (Brewfile)
# ==========================================

if [ -f "$PACKAGES_DIR/Brewfile" ]; then
  loginfo "Checking Homebrew..."
  if ! command -v brew >/dev/null 2>&1; then
    loginfo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add brew to path temporarily so the script can continue
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
  
  loginfo "Installing Brewfile packages..."
  brew bundle --file="$PACKAGES_DIR/Brewfile"
else
  logwarn "Brewfile not found. Skipping step."
fi

# ==========================================
# 4. Flatpaks
# ==========================================

if [ -f "$PACKAGES_DIR/flatpaks.txt" ]; then
  loginfo "Checking Flatpak..."
  if ! command -v flatpak >/dev/null 2>&1; then
    $INSTALL_CMD flatpak
  fi

  loginfo "Adding Flathub repository..."
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

  loginfo "Installing Flatpaks..."
  xargs -a "$PACKAGES_DIR/flatpaks.txt" flatpak install -y
else
  logwarn "Flatpak list not found."
fi

# ==========================================
# 5. Ghostty config
# ==========================================

eval $GHOSTTY_CMD

# ==========================================
# 6. Zsh config
# ==========================================

# Set ZSH as default shell if installed
if command -v zsh >/dev/null; then
  if [ "$SHELL" != "$(which zsh)" ]; then
    loginfo "Setting ZSH as default shell..."
    chsh -s "$(which zsh)"
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
  # Pyenv e uv
  loginfo "Installing Pyenv and uv..."
  rm -Rf "${HOME}/.pyenv"
  curl -fsSL https://pyenv.run | bash
else
  loginfo "Pyenv already installed..."
fi

if ! command -v uv &> /dev/null; then
  # UV 
  loginfo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
else
  loginfo "UV already installed..."
fi

if ! command -v nvm &> /dev/null; then
  # NVM
  rm -Rf "${HOME}/.nvm"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
else
  loginfo "NVM already installed..."
fi

# ==========================================
# 10. Dotfiles Links (NO BACKUP)
# ==========================================

loginfo "Creating symlinks (Overwriting existing files)..."

# Function to link files WITHOUT backup (Overwrites)
link_file() {
  local src="$1"
  local dest="$2"

  # Create parent directory if it doesn't exist
  mkdir -p "$(dirname "$dest")"

  # Check if it's already a correct link
  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]; then
    loginfo "Already linked: $dest"
    return
  fi

  # Remove existing file/folder/link regardless of what it is
  if [ -e "$dest" ] || [ -h "$dest" ]; then
    logwarn "Removing existing file: $dest"
    rm -rf "$dest"
  fi

  # Create the link
  ln -s "$src" "$dest"
  logsuccess "Linked: $src -> $dest"
}

# File mapping
# Format: link_file "SOURCE" "DESTINATION"

# ZSH
link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
rm -Rf "$ZSH_CUSTOM/themes/omtheme.zsh-theme"
ln -sf "$HOME/dotfiles/zsh/config/omtheme.zsh-theme" "$ZSH_CUSTOM/themes/omtheme.zsh-theme"
# Git
link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# Tmux
link_file "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
# Tmux scripts (Ensure directory structure exists for scripts referenced in conf)
mkdir -p "$HOME/dotfiles/tmux/scripts" 

# Neovim
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# Ghostty
link_file "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"

# Fastfetch
link_file "$DOTFILES_DIR/fastfetch" "$HOME/.config/fastfetch"

# VSCode (Linux)
if [ -d "$HOME/.config/Code/User" ]; then
    link_file "$DOTFILES_DIR/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
    link_file "$DOTFILES_DIR/vscode/keybindings.json" "$HOME/.config/Code/User/keybindings.json"
fi

# Vim
link_file "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"

# ==========================================
# 11. Finalization
# ==========================================


loginfo "Installation complete! Restart your terminal or log out."
