
# print to stderr, red color
kv_echo_err() {
	echo -e "\e[01;31m$@\e[0m" >&2
}

# Usage: kv_validate_key <key>
kv_validate_key() {
	[[ "$1" =~ ^[0-9a-zA-Z._:-]+$  ]]
}

# Usage: kvget <key>
kvget() {
	key="$1"
	kv_validate_key "$key" || {
		_failure "db" 'invalid param "key"'
		return 1
	}
	kv_user_dir=${KV_USER_DIR:-$DEFAULT_KV_USER_DIR}
	value="$([ -f "$kv_user_dir/$key" ] && cat "$kv_user_dir/$key")"
	echo "$value"
	
	[ "$value" != "" ]
}

# Usage: kvset <key> [value] 
kvset() {
	key="$1"
	value="$2"
	kv_validate_key "$key" || {
        _failure "db" 'invalid param "key"'
		return 1
	}
	kv_user_dir=${KV_USER_DIR:-$DEFAULT_KV_USER_DIR}
	test -d "$kv_user_dir" || mkdir "$kv_user_dir"
	echo "$value" > "$kv_user_dir/$key"
    _message "${key} => ${value}"
}

# Usage: kvdel <key>
kvdel() {
	key="$1"
	kv_validate_key "$key" || {
        _failure "db" 'invalid param "key"'
		return 1
	}
	kv_user_dir=${KV_USER_DIR:-$DEFAULT_KV_USER_DIR}
	test -f "$kv_user_dir/$key" && rm -f "$kv_user_dir/$key"
    _message "Deleted key '${key}'"
}

# list all key/value pairs to stdout
# Usage: kvlist
kvlist() {
	kv_user_dir=${KV_USER_DIR:-$DEFAULT_KV_USER_DIR}
	for i in "$kv_user_dir/"*; do
		if [ -f "$i" ]; then
			key="$(basename "$i")"
			echo "$key" "$(kvget "$key")"
		fi
	done 
}

# clear all key/value pairs in database
# Usage: kvclear
kvclear() {
    rm -rf "${KV_USER_DIR:-$DEFAULT_KV_USER_DIR}"
}
