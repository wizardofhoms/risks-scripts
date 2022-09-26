
# _encrypt_filename takes a filename, an identity and a passphrase as input, 
# generates an password as output. This password/output is used as the new, 
# encrypted name for the file.
# usage: filename=$(_encrypt_filename "$file" "$user" "$pass")
_encrypt_filename ()
{
    local filename="$1"
    local identity="$2"
    local pass="$3"

    # -q            Quiet: just output the password/filename
    # -n            Don't append a newline to the password output
    # -s 0          Read passphrase from stdinput (fd 0)
    # -F n          No config file output
    # -t n          Output a nine characters name, without symbols
    # -u ${user}    User for which to produce the password/name
    local encrypted=$(print "${pass}" | spectre -q -n -s 0 -F n -t n -u ${identity} ${filename})
    print "${encrypted}"
}

# Returns a spectre-generated passphrase, given an identity and an optional password argument.
# - No argument: spectre will prompt for a passphrase, which is essentially creating
#                a new one to be used in later steps.
# - With arg:    spectre uses it to produce an output without any prompt.
#
# usage: password=$(_passphrase "${identity}" ${master_passphrase})
passphrase ()
{
    local identity=${1}
    local master="${2}"

    # The `risks` argument is common to all, since it's not specific to anything.
    local cmd=(spectre -q -n -F n)
    local parameters=(-t K -P 512 -u ${identity} risks)

    if [[ ! -z ${master} ]]; then
        local passphrase=$(print "${master}" | ${cmd} -s 0 ${parameters})
    else
        local passphrase=$(${cmd} ${parameters})
    fi

    print "${passphrase}"
}
