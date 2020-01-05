# .bashrc is sourced by interactive non-login shells. However, we source it
# manually from .profile for login shells too.

# Stop if not an interactive session.
[[ $- != *i* ]] && return

PS1='\u@\h \W\$ '

err() {
	printf "\033[1;31m%s\033[0m\n" "$*" >&2
}

# Force tmux for remote sessions 
if [[ -n "$SSH_CONNECTION" && -z "$TMUX" ]]; then
	if [[ "$SSH_CONNECTION" == '::1 '* ]] || [[ "$SSH_CONNECTION" == '127.0.0.1 '* ]]; then
		err 'Warning! skipping tmux for ssh localhost'
	elif type tmux &> /dev/null; then
		# Try to attach to an existing session.
		# Set /bin/bash explicitly so a login shell is avoided because presumably we
		# just came from a login shell.
		exec /usr/bin/tmux new-session -A -s 0 /bin/bash
	else
		err 'Warning! tmux not available!'
	fi
fi

# Check for alacritty terminfo
if [[ "$TERM" = alacritty && ! -e /usr/share/terminfo/a/alacritty ]]; then
	err 'Warning! TERM=alacritty not available, switching to TERM=xterm-256color'
	export TERM=xterm-256color
fi

prompt_command() {
	printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"
}; export PROMPT_COMMAND=prompt_command

# common:
	export PAGER=less
	export EDITOR=vim

# bash history:
	HISTCONTROL=ignoreboth
	HISTSIZE=1000
	HISTFILESIZE=10000
	grep-hist() {
		grep "$@" ~/.bash_history
	}
	alias grep-bash=grep-hist

# ps:
	export PS_FORMAT=user,tty,%cpu,%mem,sz,vsz,rss,ppid,pid,bsdtime,nlwp,args

# ls
	# This doesn't seem necessary anymore
	# eval $(dircolors -b)
	alias ls='ls --color=auto --group-directories-first'
	alias lsa='ls -A'
	alias ll='ls -lh'
	alias la='ll -a'

# less:
	# Mouse support is quite new so test for it in --help. Without it, most
	# terminal emulators need to translate scroll to key presses. Tmux
	# won't do this though so without true less mouse support a lot of very
	# hacky tmux config is required to get scrolling in less.
	if [[ "$LESS" != *--mouse* ]]; then
		if less --help | grep -q -s -- --mouse; then
			export LESS="$LESS --mouse --wheel-lines=3"
		elif [[ $TMUX ]]; then
			err 'Warning! tmux without less --mouse support.'
		fi
	fi

	# color support, especially for man pages
	export LESS_TERMCAP_mb=$'\E[01;31m'
	export LESS_TERMCAP_md=$'\E[01;31m'
	export LESS_TERMCAP_me=$'\E[0m'
	export LESS_TERMCAP_se=$'\E[0m'
	export LESS_TERMCAP_so=$'\E[01;44;33m'
	export LESS_TERMCAP_ue=$'\E[0m'
	export LESS_TERMCAP_us=$'\E[01;32m'
	# filter the above out of `env` since they pollute the terminal
	env() { command env $@ | grep -v LESS_TERMCAP_ | sort; }

start-sway() {
	declare -a hwmons=(/sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input)
	if (( ${#hwmons[@]} != 1 )); then
		echo "Could not determine hwmon path"
		return
	fi
	sed -r "s|[^\"]*coretemp.0[^\"]*|${hwmons[0]}|" -i ~/.config/waybar/config

	exec systemd-cat -t sway --priority info --stderr-priority err /usr/bin/sway -d
}

# dotfiles:
	# Making a normal repo out of $HOME (with $HOME/.git) can be confusing
	# and lead to mistakes. Instead store dotfiles.git as a bare repo. Yes,
	# this masks dot(1) from graphviz but I never use that.
	alias dot="/usr/bin/git --git-dir='$HOME/.config/dotfiles.git' --work-tree='$HOME'"
	# I don't remember why this is necessary :/
	_completion_loader git
	# Sort of `complete -p git | sed 's/git$/dot/'
	complete -o bashdefault -o default -o nospace -F _git dot

# Allow bashrc snippets. I'm hot-and-cold on whether this is cleaner or not.
# At least two good usecases are 1) large/messy snippets, 2) scratch or local
# snippets that I don't want to track with dotfiles.git
for f in ~/.config/bash.d/*.sh; do
	[[ -r $f ]] && source "$f"
done
unset f
