#!/usr/bin/env zsh

# Homebrew
eval "$($HOME/.linuxbrew/bin/brew shellenv)"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Pyenv (base, sem init pesado)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# NVM (base, sem carregar)
export NVM_DIR="$HOME/.nvm"

# Env local
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

