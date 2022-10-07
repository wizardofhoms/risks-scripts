
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

# Retrieves the value of a variable first by looking in the risk
# config file, and optionally overrides it if the flag is set.
# $1 - Flag argument
# $2 - Key name in config
config_or_flag () 
{
    local value config_value

    config_value=$(config_get $2)   # From config
    value="${1-$config_value}"      # overriden by flag if set

    print $value
}
