
# dot-untracked helps list out files that are untracked by any dotfiles repo which is
# non-trivial since there can be an arbitrary number of said repos all layered over the
# same $HOME directory. Further, it's not practical to be completely precise so there
# is a list of excluded dirs and then ignored files.
dot-untracked() {
	declare -ra repos=(~/.config/dotfiles*.git)
	declare -ra exclude_dirs=(
		'\.'
		'\.config'
		'\.config/dotfiles.*\.git'
	)
	declare -ra ignore_files=(
		'\.config/vim/.netrwhist'
		'\.gnupg/.*\.kbx~?'
		'\.gnupg/reader_[0-9]+.status'
		'\.gnupg/sshcontrol'
		'\.gnupg/trustdb.gpg'
		'\.kube/cache/.*'
		'\.kube/gke_gcloud_auth_plugin_cache'
		'\.ssh/known_hosts(.old)?'
	)

	declare -a git_files
	mapfile -t git_files < <(
		cd "$HOME"
		local r
		for r in "${repos[@]}"; do
			git --git-dir="$r" --work-tree="$HOME" ls-files
		done \
		| sort | uniq
	)
	declare -ra git_files
	declare -a git_dirs
	mapfile -t git_dirs < <(
		declare -a grep=(grep -Ev)
		local e
		for e in "${exclude_dirs[@]}"; do grep+=(-e "^$e$"); done
		dirname "${git_files[@]}" | "${grep[@]}" | sort | uniq
	)
	declare -ra git_dirs

	declare -a all_files
	mapfile -t all_files< <(
		cd "$HOME"
		declare -a grep=(grep -Ev)
		local e
		for e in "${ignore_files[@]}"; do grep+=(-e "^$e$"); done
		find "${git_dirs[@]}" \! -type d | "${grep[@]}" | sort | uniq
	)
	declare -ra all_files

	comm -13 <(printf "%s\n" "${git_files[@]}") <(printf "%s\n" "${all_files[@]}")
}
