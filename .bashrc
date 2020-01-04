# .bashrc is sourced by interactive non-login shells. However, we source it
# manually from .profile for login shells too.

# Stop if not an interactive session.
[[ $- != *i* ]] && return

PS1='\u@\h \W\$ '

prompt_command() {
	case $TERM in
	xterm*|gnome*|alacritty*)
		printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"
		;;
	screen)
		printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"
		;;
	*)
		printf "\033]0;%s@%s:%s (default)\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"
	esac
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

# ls
	# This doesn't seem necessary anymore
	# eval $(dircolors -b)
	alias ls='ls --color=auto --group-directories-first'
	alias lsa='ls -A'
	alias ll='ls -lh'
	alias la='ll -a'

# dotfiles:
	# Making a normal repo out of $HOME (with $HOME/.git) can be confusing
	# and lead to mistakes. Instead store dotfiles.git as a bare repo. Yes,
	# this masks dot(1) from graphviz but I never use that.
	alias dot="/usr/bin/git --git-dir='$HOME/.config/dotfiles.git' --work-tree='$HOME'"
	# I don't remember why this is necessary :/
	_completion_loader git
	# Sort of `complete -p git | sed 's/git$/dot/'
	complete -o bashdefault -o default -o nospace -F _git dot
