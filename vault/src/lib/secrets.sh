
# _encrypt_filename taks a filename and an identity as input.
# It uses the identity both as the username AND the input password,
# so that we can avoid asking passwords to the identity each time.
_encrypt_filename ()
{
    local filename="$1"
    local identity="$2"
    local encrypted

    # -q            Quiet: just output the password/filename
    # -n            Don't append a newline to the password output
    # -s 0          Read passphrase from stdinput (fd 0)
    # -F n          No config file output
    # -t n          Output a nine characters name, without symbols
    # -u ${user}    User for which to produce the password/name
    encrypted=$(print "${identity}" | spectre -q -n -s 0 -F n -t n -u "${identity}" "${filename}")
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

    local passphrase

    # If the call did include neither a passname and a master password,
    # we set the passname to master: this will output the passphrase used
    # to obfuscate and encrypt file/directory names, as well as the phrase
    # used to derive further passphrases, such as the GPG one.
    if [[ ${#@} -eq 1 ]]; then
        passname="master"
    fi

    # Forge command
    local cmd=(spectre -q -n -F n)
    local spectre_params=(-t K -P 512 -u "$identity" "$passname")

    # Optionally derive the passphrase we want from a master passphrase;
    # this has for effect of not prompting the user for it.
    if [[ -n $MASTER_PASS ]]; then
        passphrase=$(print "$MASTER_PASS" | "${cmd[@]}" -s 0 "${spectre_params[@]}")
    else
        passphrase=$("${cmd[@]}" "${spectre_params[@]}")
    fi

    print "$passphrase"
}
