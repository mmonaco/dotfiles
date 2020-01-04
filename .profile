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

# logind doesn't seem to set this (I think it sets the other XDG vars)
[ -z "$XDG_CONFIG_HOME" ] && export XDG_CONFIG_HOME="$HOME/.config"

# Allow profile snippets. I'm hot-and-cold on whether this is cleaner or not.
# At least two good usecases are 1) large/messy snippets, 2) scratch or local
# snippets that I don't want to track with dotfiles.git
for f in "$HOME"/.config/profile.d/*.sh; do
	[ -r "$f" ] && source "$f"
done
unset f

# We still want bashrc for non-login shells, bash doesn't source it for us.
[ -r "$HOME"/.bashrc ] && source "$HOME"/.bashrc
