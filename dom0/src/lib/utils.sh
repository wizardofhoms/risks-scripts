
# Return 0 if is set, 1 otherwise
option_is_set() {
	local -i r	 # the return code (0 = set, 1 = unset)

	[[ -n ${(k)OPTS[$1]} ]];
	r=$?

	[[ $2 == "out" ]] && {
		[[ $r == 0 ]] && { print 'set' } || { print 'unset' }
	}

	return $r;
}

