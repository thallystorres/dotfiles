#!/usr/bin/env bash
# wsl/post-install.sh
# Runs INSIDE the Fedora WSL distro after setup-wsl.ps1 creates it.
# Calls the main install.sh in WSL mode, then wires opencode + Codex CLI.
# Idempotent: every step checks before acting.
#
# Usage (from repo root inside WSL):
#   sudo bash wsl/post-install.sh                     # uses current user
#   sudo bash wsl/post-install.sh --user thallys
set -euo pipefail

USER_NAME="$(id -un)"
CODEX_VERSION="latest"   # pin a real version (e.g. 0.30.0) to lock reproducibility

while [ $# -gt 0 ]; do
  case "$1" in
    --user) USER_NAME="$2"; shift 2 ;;
    *) shift ;;
  esac
done

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DOTFILES_DIR"

echo "==> Ensuring sudo / wheel works for $USER_NAME"
if ! id "$USER_NAME" >/dev/null 2>&1; then
  echo "user $USER_NAME does not exist; create it first (setup-wsl.ps1 does this)." >&2
  exit 1
fi
# Ensure wheel group members can sudo without password (common WSL convenience).
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel-nopasswd || true
usermod -aG wheel "$USER_NAME" || true

echo "==> dnf upgrade"
dnf upgrade -y

echo "==> Running dotfiles install.sh --wsl"
# --no-packages because post-install.sh handles dnf itself; install.sh then
# does Homebrew/zsh/oh-my-zsh/lazy.nvim/TPM/pyenv/uv/nvm + symlinks, skipping
# GNOME, Ghostty, flatpak, linux.toys.
bash install.sh --wsl --no-packages || {
  echo "install.sh reported a failure; inspect $DOTFILES_DIR/install.log" >&2
}

echo "==> Installing opencode into WSL"
# opencode ships its own installer; bin lands in ~/.opencode/bin (the zshrc
# already prepends that to PATH when present).
if ! command -v opencode >/dev/null 2>&1 && [ ! -x "$HOME/.opencode/bin/opencode" ]; then
  curl -fsSL https://opencode.ai/install | bash
else
  echo "    opencode already installed"
fi

echo "==> Installing OpenAI Codex CLI into WSL"
# Load NVM so npm is on PATH for this script.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
if command -v npm >/dev/null 2>&1; then
  if [ "$CODEX_VERSION" = "latest" ]; then
    npm install -g "@openai/codex"
  else
    npm install -g "@openai/codex@$CODEX_VERSION"
  fi
else
  echo "    npm not on PATH yet; install NVM via install.sh first, then run:" >&2
  echo "    npm i -g @openai/codex" >&2
fi

echo "==> WSL posinstall complete."
echo "    Restart WSL (wsl --terminate Fedora43) and open a new shell."
echo "    Verify: fastfetch, nvim, tmux, opencode --version, codex --version."