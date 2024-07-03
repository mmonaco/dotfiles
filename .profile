# .profile is sourced by interactive login shells only
#
# This file will be sourced by sh(1) or other shells on a rare occassion so
# avoid modern things like `[[`. Switch to .bash_profile otherwise.

# Default user=rwX group=rX other=rX for file creation
umask 0022

err() {
	printf "\033[1;31m%s\033[0m\n" "$*" >&2
}

# Local bin dir (and try to only add it once)
add_path() {
	local path
	for path in "$@"; do
		[[ -d "$path" ]] || continue
		[[ "${PATH#*$path:}" == "$PATH" ]] || continue
		export PATH="$path:$PATH"
	done
}
add_path "$HOME/.config/bin" "$HOME/.local/bin"

# logind doesn't seem to set this (I think it sets the other XDG vars)
[[ "$XDG_CONFIG_HOME" ]] || export XDG_CONFIG_HOME="$HOME/.config"

# SSH/GPG Agent
if [[ -z "$SSH_AUTH_SOCK" ]]; then
	if systemctl --user is-active --quiet gpg-agent-ssh.socket; then
		export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
		unset SSH_AGENT_PID
	fi
fi

# Allow profile snippets. I'm hot-and-cold on whether this is cleaner or not.
# At least two good usecases are 1) large/messy snippets, 2) scratch or local
# snippets that I don't want to track with dotfiles.git
for f in "$HOME"/.config/profile.d/*.sh; do
	[[ -r "$f" ]] && source "$f"
done
unset f

# Force tmux for remote sessions 
if [[ -n "$SSH_CONNECTION" && -z "$TMUX" ]]; then
	if [[ "$SSH_CONNECTION" == '::1 '* ]] || [[ "$SSH_CONNECTION" == '127.0.0.1 '* ]]; then
		err 'Warning! skipping tmux for ssh localhost'
	elif type tmux &> /dev/null; then
		# Try to attach to an existing session.
		# Set /bin/bash explicitly so a login shell is avoided because presumably we
		# just came from a login shell.
		tmux_unattached=$(tmux list-sessions | grep -v attached | cut -d: -f1 | head -n1)
		if [[ $tmux_unattached ]]; then
			exec /usr/bin/tmux attach-session -t "$tmux_unattached"
		else
			exec /usr/bin/tmux new-session /bin/bash
		fi
	else
		err 'Warning! tmux not available!'
	fi
fi

# We still want bashrc for non-login shells, bash doesn't source it for us.
[[ -r "$HOME"/.bashrc ]] && source "$HOME"/.bashrc
