# .profile is sourced by interactive login shells only
#
# This file will be sourced by sh(1) or other shells on a rare occassion so
# avoid modern things like `[[`. Switch to .bash_profile otherwise.

# Default user=rwX group=rX other=rX for file creation
umask 0022

# Local bin dir (and try to only add it once)
if [ -d "$HOME/.local/bin" -a "${PATH#*$HOME/.local/bin:}" == "$PATH" ]; then
	export PATH="$HOME/.local/bin:$PATH"
fi

# We still want bashrc for non-login shells, bash doesn't source it for us.
[ -r "$HOME"/.bashrc ] && source "$HOME"/.bashrc
