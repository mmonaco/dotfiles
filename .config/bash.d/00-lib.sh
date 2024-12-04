#!/bin/bash

if [[ -z "$bold" ]]; then
	# Don't bother with tput, these are pretty universal sequences
	declare -r   bold=$'\E[1m'
	declare -r    red=$'\E[31m'
	declare -r   bred=$'\E[1;31m'
	declare -r  green=$'\E[32m'
	declare -r bgreen=$'\E[1;32m'
	declare -r   blue=$'\E[34m'
	declare -r  bblue=$'\E[1;34m'
	declare -r reset_term=$'\E[0m'
fi

run() {
	local color="$1"; shift
	printf "%s%s%s\n" "$color" "$*" "$reset_term" >&2
	"$@"
}

run-green() {
	run "$bgreen" "$@"
}

err() {
	local fmt="$1"; shift
	printf "%s""$fmt""%s\n" "$bred" "$@" "$reset_term" >&2
}
