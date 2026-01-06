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

# 1. Package Manager Detection

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

# 2. System Update and Packages

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
  grep -vE '^\s*$' "$PACKAGES_DIR/flatpaks.txt" | while read -r app; do
    flatpak install -y flathub "$app"
  done
else
  logwarn "Flatpak list not found."
fi

# ==========================================
# 5. Dotfiles Links (NO BACKUP)
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
link_file "$DOTFILES_DIR/dotfile/zsh/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/dotfile/zsh/.zprofile" "$HOME/.zprofile"

# Git
link_file "$DOTFILES_DIR/dotfile/git/.gitconfig" "$HOME/.gitconfig"

# Tmux
link_file "$DOTFILES_DIR/dotfile/tmux/.tmux.conf" "$HOME/.tmux.conf"
# Tmux scripts (Ensure directory structure exists for scripts referenced in conf)
mkdir -p "$HOME/dotfiles/dotfile/tmux/scripts" 

# Neovim
link_file "$DOTFILES_DIR/dotfile/nvim" "$HOME/.config/nvim"

# Ghostty
link_file "$DOTFILES_DIR/dotfile/ghostty" "$HOME/.config/ghostty"

# Fastfetch
link_file "$DOTFILES_DIR/dotfile/fastfetch" "$HOME/.config/fastfetch"

# VSCode (Linux)
if [ -d "$HOME/.config/Code/User" ]; then
    link_file "$DOTFILES_DIR/dotfile/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
    link_file "$DOTFILES_DIR/dotfile/vscode/keybindings.json" "$HOME/.config/Code/User/keybindings.json"
fi

# Vim
link_file "$DOTFILES_DIR/dotfile/vim/.vimrc" "$HOME/.vimrc"

# ==========================================
# 6. Finalization
# ==========================================

# Set ZSH as default shell if installed
if command -v zsh >/dev/null; then
  if [ "$SHELL" != "$(which zsh)" ]; then
    loginfo "Setting ZSH as default shell..."
    chsh -s "$(which zsh)"
  fi
fi

loginfo "Installation complete! Restart your terminal or log out."
