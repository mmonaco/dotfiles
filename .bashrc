# .bashrc is sourced by interactive non-login shells. However, we source it
# manually from .profile for login shells too.

# Stop if not an interactive session.
[[ "${-##*i*}" ]] && return

PS1='\u@\h \W\$ '

err() {
	printf "\033[1;31m%s\033[0m\n" "$*" >&2
}

# Check for alacritty terminfo
if [[ "$TERM" = alacritty && ! -e /usr/share/terminfo/a/alacritty ]]; then
	err 'Warning! TERM=alacritty not available, switching to TERM=xterm-256color'
	export TERM=xterm-256color
fi

prompt_command() {
	printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"
}; export PROMPT_COMMAND=prompt_command

# ssh/gpg-agent:
	# I keep trying to decide if handling SSH_AUTH_SOCK should be in
	# .profile or .bashrc. However, with updatestartuptty as well, I think
	# it's more clearly bashrc.
	if [[ -z "$SSH_AUTH_SOCK" ]]; then
		export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
		unset SSH_AGENT_PID
	fi
	if [[ "$SSH_AUTH_SOCK" == */S.gpg-agent.ssh ]]; then
		systemd-cat -t gpg-connect-agent \
			gpg-connect-agent -q updatestartuptty /bye
	fi

# bash-completion:
	# some distros source this from a system-wide bashrc, some from
	# system-wide profile, some from initial copies from /etc/skel, ...
	if [[ -z $BASH_COMPLETION_VERSINFO && -r /usr/share/bash-completion/bash_completion ]]; then
		source /usr/share/bash-completion/bash_completion
	fi

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

# man:
	# Remap bold, underline, etc to colorized sequences. These are all
	# basic sequences that seem to be the same for every $TERM I encounter,
	# so don't bother with tput(1).
	man() {
		# termcap | terminfo | description
		#   mb    |  blink   | "start blink"
		#   md    |  bold    | "start bold"
		#   me    |  sgr0    | "turn off blink, bold, underline"
		#   so    |  smso    | "start standout (reverse video)
		#   se    |  rmso    | "stop standout"
		#   us    |  smul    | "start underline"
		#   ue    |  rmul    | "stop underline"
		#
		LESS_TERMCAP_mb=$'\E[1;36m' \
		LESS_TERMCAP_md=$'\E[1;31m' \
		LESS_TERMCAP_me=$'\E[0m' \
		LESS_TERMCAP_so=$'\E[1;33;44m' \
		LESS_TERMCAP_se=$'\E[0m' \
		LESS_TERMCAP_us=$'\E[1;32m' \
		LESS_TERMCAP_ue=$'\E[0m' \
		command man "$@"
	}

# misc aliases and wrappers:
	env() { command env "$@" | sort; }
	alias grep='grep --color=auto'
	alias tree='tree -C --dirsfirst'
	alias cp='cp --reflink=auto'
	alias vim='vim -p'
	alias df='df -H'
	alias R="R --no-save"
	alias ffmpeg='ffmpeg -hide_banner'
	alias ffprobe='ffprobe -hide_banner'
	alias srsync='rsync --rsync-path="sudo rsync"'

# misc custom utils:
	alias rename="vim -cRename"
	alias vimt='column -t | vim - +"set nowrap"'
	alias ash='/usr/lib/initcpio/busybox ash'
	alias bashrc='source ~/.bashrc'
	alias gcd='cd $(git rev-parse --show-toplevel)'
	alias pp='sudo ~/src/monaco.pp/puppet.sh'
	eject() { [[ $1 ]] && sudo tee /sys/block/"$1"/device/delete <<<1 ; }
	alias dateh='date --help|sed "/^ *%a/,/^ *%Z/!d;y/_/!/;s/^ *%\([:a-z]\+\) \+/\1_/gI;s/%/#/g;s/^\([a-y]\|[z:]\+\)_/%%\1_%\1_/I"|while read L;do date "+${L}"|sed y/!#/%%/;done|column -ts_'
	alias gccopts="gcc -march=native -E -v - </dev/null 2>&1 | sed -n 's/.* -v - //p'"
	randmac() {
		perl -e 'for ($i=0;$i<5;$i++){@m[$i]=int(rand(256));} printf "02:%x:%x:%x:%x:%x\n",@m;'
	}
	docker-rmi() {
		declare -a images=(
			$(docker images | awk '/^<none>/ { print $3 }')
			"$@"
		)
		[[ $images ]] && docker rmi "${images[@]}"
	}
	d-centos() { docker run -ti --rm --name centos -h centos "$@" mmonaco/centos ; }
	d-ubuntu() { docker run -ti --rm --name ubuntu -h ubuntu "$@" ubuntu ; }
	d-debian() { docker run -ti --rm --name debian -h debian "$@" debian:8 ; }

	start-sway() {
		# This is sort of a standard. At least some programs use it to
		# determine X11 vs Wayland. The logind session will still be
		# Type=tty; AFAIK there's no way to change it once logged in by
		# pam_systemd/logind.
		XDG_SESSION_TYPE=wayland \
		exec systemd-cat -t sway --priority info --stderr-priority err /usr/bin/sway -d
	}

# systemd:
if type systemctl &> /dev/null; then
	SD=/etc/systemd/system
	LSD=/lib/systemd/system
	UD=~/.config/systemd/user
	LUD=/usr/lib/systemd/user
	EUD=/etc/systemd/user

	alias sd="sudo systemctl"
	alias ud="systemctl --user"

	alias log=journalctl
	alias ulog='journalctl --user'

	_completion_loader systemctl
	_completion_loader journalctl
	complete -F _systemctl -o default sd
	complete -F _systemctl -o default ud
	complete -F _journalctl -o default log
	complete -F _journalctl -o default ulog

	alias cgls="systemd-cgls"
fi

# package management:
	if type pacman &> /dev/null; then
		update() {
			sudo pacman -Syuu
			type auracle &> /dev/null && auracle outdated
		}
		alias pm='sudo pacman'
		_completion_loader pacman
		complete -F _pacman -o default pm
	elif type yum &> /dev/null; then
		update() {
			sudo yum upgrade
		}
	fi

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
