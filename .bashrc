# .bashrc is sourced by interactive non-login shells. However, we source it
# manually from .profile for login shells too.

# Stop if not an interactive session.
[[ "${-##*i*}" ]] && return

# Autostart (tmux, sway, bash)
	start-sway() {
		MOZ_ENABLE_WAYLAND=1 \
		exec systemd-cat -t sway --priority info --stderr-priority err /usr/bin/sway -d
	}
	if [[ -z "$WAYLAND_DISPLAY" && $(tty) == /dev/tty1 ]]; then
		start-sway
	elif [[ -n "$SSH_CONNECTION" && -z "$TMUX" ]]; then
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


# git PS1 support (if available)
	if ! type -t __git_ps1 &> /dev/null && [[ -f /usr/share/git/completion/git-prompt.sh ]]; then
		source /usr/share/git/completion/git-prompt.sh
	fi
	___git_ps1() {
		type -t __git_ps1 &> /dev/null || return
		GIT_PS1_SHOWCOLORHINTS=1
		GIT_PS1_SHOWDIRTYSTATE=1
		GIT_PS1_SHOWSTASHSTATE=1
		GIT_PS1_SHOWUNTRACKEDFILES=1
		GIT_PS1_SHOWUPSTREAM="auto"
		__git_ps1 "$@"
	}

BASE_PS1='\u@\h$(___git_ps1 " [%s]") \W\$ '
PS1="$BASE_PS1"

err() {
	printf "\033[1;31m%s\033[0m\n" "$*" >&2
}

# Check for alacritty terminfo
if [[ "$TERM" = alacritty && ! -e /usr/share/terminfo/a/alacritty ]]; then
	err 'Warning! TERM=alacritty not available, switching to TERM=xterm-256color'
	export TERM=xterm-256color
fi

_prompt_command() {
	printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"
	# reboot-required defined below
	reboot-required -q && PS1="[REBOOT] $BASE_PS1" || PS1="$BASE_PS1"
}
declare -a PROMPT_COMMAND=(_prompt_command)

# ssh/gpg-agent:
	if [[ "$SSH_AUTH_SOCK" == */S.gpg-agent.ssh ]]; then
		systemd-cat -t gpg-connect-agent gpg-connect-agent -q updatestartuptty /bye
	fi
	export GPG_TTY=$(tty)

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
	alias ls='ls --color=auto --group-directories-first'
	alias lsa='ls -A'
	alias ll='ls -lh'
	alias la='ll -a'
	alias tree='tree -C --dirsfirst'

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
	export LESS="$LESS -R --use-color -Dd+r\$Du+b\$"

# man
	export MANROFFOPT='-P -c'	

# misc aliases, wrappers, utils:
	env() { command env "$@" | sort; }
	alias grep='grep --color=auto'
	alias cp='cp --reflink=auto'
	alias vim='vim -p'
	alias vimrc='vim ~/.config/vim/vimrc'
	alias df='df -H'
	alias srsync='rsync --rsync-path="sudo rsync"'
	alias bashrc='source ~/.bashrc'
	alias gcd='cd $(git rev-parse --show-toplevel)'
	alias ct='tmux choose-tree'

	alias dateh='date --help|sed "/^ *%a/,/^ *%Z/!d;y/_/!/;s/^ *%\([:a-z]\+\) \+/\1_/gI;s/%/#/g;s/^\([a-y]\|[z:]\+\)_/%%\1_%\1_/I"|while read L;do date "+${L}"|sed y/!#/%%/;done|column -ts_'
	alias notes="vim ~/notes"
	alias ffmpeg='ffmpeg -hide_banner'
	alias ffprobe='ffprobe -hide_banner'
	randmac() {
		perl -e 'for ($i=0;$i<5;$i++){@m[$i]=int(rand(256));} printf "02:%x:%x:%x:%x:%x\n",@m;'
	}

# systemd:
if type systemctl &> /dev/null; then
	SD=/etc/systemd/system
	LSD=/lib/systemd/system
	UD=~/.config/systemd/user
	LUD=/usr/lib/systemd/user
	EUD=/etc/systemd/user

	alias sd='systemctl'
	alias ud='systemctl --user'

	alias log='journalctl --system'
	alias ulog='journalctl --user'
	alias warnings='journalctl --system --boot --priority=warning'

	alias mc='machinectl'
	alias rc='resolvectl'

	_completion_loader systemctl
	_completion_loader journalctl
	_completion_loader machinectl
	_completion_loader resolvectl
	complete -F _systemctl -o default sd ud
	complete -F _journalctl -o default log ulog warnings
	complete -F _machinectl -o default mc
	complete -F _resolvectl -o default rc

	alias cgls='systemd-cgls'
fi

# package management:
	if type pacman &> /dev/null; then
		update() {
			/usr/bin/sudo /usr/bin/pacman -Syuu
			if type auracle &> /dev/null; then
				printf "\E[1;34m:: \E[1;37mRunning auracle outdated\E[0m\n" >&2
				/usr/bin/auracle outdated
			fi
			printf "\E[1;34m:: \E[1;37mRunning pacman -Qdt\E[0m\n" >&2
			/usr/bin/pacman -Qdt
			if [[ ! -f /etc/pacman.d/hooks/arch-audit.hook ]]; then
				printf "\E[1;34m:: \E[1;37mRunning arch-audit\E[0m\n" >&2
				/usr/bin/arch-audit
			fi
			printf "\E[1;34m:: \E[1;37mRunning pacdiff --output\E[0m\n" >&2
			/usr/bin/pacdiff --output
		}
		pacman-modified() { pacman -Qii | awk '/\[modified\]/ {print $(NF - 1)}'; }
		alias pm='sudo pacman'
		_completion_loader pacman
		complete -F _pacman -o default pm
	elif type yum &> /dev/null; then
		update() {
			sudo yum upgrade
		}
	elif type apt &> /dev/null; then
		update() {
			sudo apt update
			sudo apt dist-upgrade
			sudo apt autoremove --purge
			sudo apt autoclean
		}
	fi

# dotfiles:
	# Making a normal repo out of $HOME (with $HOME/.git) can be confusing
	# and lead to mistakes. Instead store dotfiles.git as a bare repo. Yes,
	# this masks dot(1) from graphviz but I never use that.
	dot() { git --git-dir="$HOME/.config/dotfiles.git" --work-tree="$HOME" "$@"; }
	pdot() { git --git-dir="$HOME/.config/dotfiles.priv.git" --work-tree="$HOME" "$@"; }
	# I don't remember why this is necessary :/
	_completion_loader git
	# Sort of `complete -p git | sed 's/git$/dot/'
	__git_complete dot  __git_main  # Ack NOT public function warning
	__git_complete pdot __git_main  # Ack NOT public function warning

# reboot detection:
	# This is used in PROMPT_COMMAND and should be distro-agnostic
	declare _is_container=
	declare _cur_uname_r=$(uname -r)
	reboot-required() {
		[[ -z $_is_container ]] && { systemd-detect-virt -qc && _is_container=1 || _is_container=0 ; }
		(( $_is_container )) && return 1
		declare -r quiet="$1" quiet_re='^(-q|--quiet)$'
		if [[ $_cur_uname_r = *lts* ]]; then
			declare -r latest_installed=$(/bin/ls -1 /lib/modules/ | grep lts | tail -n1)
		else
			declare -r latest_installed=$(/bin/ls -1 /lib/modules/ | grep -v -e lts -e extramodules | tail -n1)
		fi
		[[ $latest_installed == $_cur_uname_r ]] && return 1
		if ! [[ $quiet =~ $quiet_re ]]; then
			printf 'REBOOT REQUIRED | Kernel Installed=<%s>; Running=<%s>\n' \
				"$latest_installed" "$_cur_uname_r" >&2
		fi
		return 0
	}

# Allow bashrc snippets. I'm hot-and-cold on whether this is cleaner or not.
# At least two good usecases are 1) large/messy snippets, 2) scratch or local
# snippets that I don't want to track with dotfiles.git
for f in ~/.config/bash.d/*.sh; do
	[[ -r $f ]] && source "$f"
done
unset f
