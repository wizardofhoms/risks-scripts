
# _set_file_encryption_key is only called once per risks run,
# and does not need any password prompt to be used: it just generates
# a deterministic key based on known inputs.
_set_file_encryption_key ()
{
    local identity="$1"
    local key
    key=$(print "$identity" | spectre -q -n -s 0 -F n -t n -u "$identity" "$FILE_ENCRYPTION")
    print "$key"
}

# _encrypt_filename takes a filename as input, and uses the currently 
# set identity to produce an random name to use as a file/directory name.
_encrypt_filename ()
{
    local filename="$1"
    local encrypted

    # -q            Quiet: just output the password/filename
    # -n            Don't append a newline to the password output
    # -s 0          Read passphrase from stdinput (fd 0)
    # -F n          No config file output
    # -t n          Output a nine characters name, without symbols
    # -u ${user}    User for which to produce the password/name
    encrypted=$(print "$FILE_ENCRYPTION_KEY" | spectre -q -n -s 0 -F n -t n -u "$IDENTITY" "$filename")
    print "${encrypted}"
}

# Returns a spectre-generated secret key, given a single name as argument.
# Uses the current IDENTITY as set by _set_identity <identity_name>
get_passphrase ()
{
    local passname="${1}"

    local passphrase

    # Forge command
    local cmd=(spectre -q -n -F n)
    local spectre_params=(-t K -P 512 -u "$IDENTITY" "$passname")

    passphrase=$("${cmd[@]}" "${spectre_params[@]}")

    print "$passphrase"
}
