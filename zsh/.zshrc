#!/usr/bin/env zsh
# vim: set filetype=zsh :

# Resolve the dotfiles dir from the symlink target of this file, so this
# works whether the repo lives at ~/dotfiles or elsewhere.
DOTFILES_DIR="${0:A:h:h}"
source "${DOTFILES_DIR}/zsh/config/use_this_to_load"

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

eval "$(zoxide init zsh)"

. "$HOME/.local/bin/env"

# opencode
[[ -d "$HOME/.opencode/bin" ]] && export PATH="$HOME/.opencode/bin:$PATH"
