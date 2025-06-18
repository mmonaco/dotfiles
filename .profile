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
	local p
	for p in "$@"; do
		case ":$PATH:" in
			*:"$p":*) ;;
			*) PATH="${p}${PATH:+:$PATH}" ;;
		esac
	done
	export PATH
}
add_path "$HOME/.config/bin" "$HOME/.local/bin"

# logind doesn't seem to set this (I think it sets the other XDG vars)
[[ "$XDG_CONFIG_HOME" ]] || export XDG_CONFIG_HOME="$HOME/.config"

# locale/LANG
if [[ ! "$LANG" ]]; then
	if command -v locale &> /dev/null; then
		if locale -a | grep -qi en_US.utf8; then
			export LANG=en_US.UTF-8
		else
			export LANG=C.UTF-8
		fi
	fi
fi

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

# We still want bashrc for non-login shells, bash doesn't source it for us.
[[ -r "$HOME"/.bashrc ]] && source "$HOME"/.bashrc
