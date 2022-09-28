
# _encrypt_filename takes a filename, an identity and a passphrase as input, 
# generates an password as output. This password/output is used as the new, 
# encrypted name for the file.
# usage: filename=$(_encrypt_filename "$file" "$user" "$pass")
_encrypt_filename ()
{
    local filename="$1"
    local identity="$2"
    local pass="$3"
    local encrypted

    # -q            Quiet: just output the password/filename
    # -n            Don't append a newline to the password output
    # -s 0          Read passphrase from stdinput (fd 0)
    # -F n          No config file output
    # -t n          Output a nine characters name, without symbols
    # -u ${user}    User for which to produce the password/name
    encrypted=$(print "${pass}" | spectre -q -n -s 0 -F n -t n -u "${identity}" "${filename}")
    print "${encrypted}"
}

# Returns a spectre-generated passphrase, given an identity, a passname and 
# an optional password argument. Two arguments are mandatory (identity & 
# passname), while the third one (master passphrase, is optional).
#
# usage: password=$(get_passphrase "${identity}" mypass ${master_passphrase})
get_passphrase ()
{
    local identity=${1}
    local passname="${2}"
    local master="${3}"

    local passphrase

    local cmd=(spectre -q -n -F n)
    local spectre_params=(-t K -P 512 -u "${identity}" "${passname}")

    if [[ -n ${master} ]]; then
        passphrase=$(print "${master}" | "${cmd[@]}" -s 0 "${spectre_params[@]}")
    else
        passphrase=$("${cmd[@]}" "${spectre_params[@]}")
    fi

    print "${passphrase}"
}
