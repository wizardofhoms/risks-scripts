# The open_command file is essentially a wrapper around several library
# functions, depending on the type of store the user wants to open.

resource="${args[resource]}"
identity="${args[identity]}" # May be empty

declare master_pass

# Either only open the GPG keyring.
if [[ "${resource}" == "gpg" ]] || [[ "${resource}" == "coffin" ]]; then
    # We need to identity argument to be non-nil
    if [[ -z ${identity} ]]; then
        _failure "The IDENTITY argument was not specified"
    fi

    _message "Opening coffin and mounting GPG keyring"
    master_pass=$(get_passphrase "${identity}")
    open_coffin "${identity}" "${master_pass}"
    exit $?
fi

# Or we either open an entire identity or some tomb,
# and then the identity argument is optional, since
# we might have one already active.
identity="$(_identity_active_or_specified "${identity}")"

# First get the master passphrase for the identity
master_pass=$(get_passphrase "${identity}")

# Then derive the gpg pass phrase from it, with one-time use
gpg_passphrase=$(get_passphrase "${identity}" "${GPG_TOMB_LABEL}" "${master_pass}")
echo -n "${gpg_passphrase}" | xclip -loops 1 -selection clipboard
_warning "Passphrase copied to clipboard with one-time use only, for GPG prompt"

# Bulk load
if [[ "${resource}" == "identity" ]]; then
    # We need to identity argument to be non-nil
    if [[ -z ${identity} ]]; then
        _failure "The IDENTITY argument was not specified"
    fi

    _message "Opening coffin and mounting GPG keyring"
    open_coffin "${identity}" "${master_pass}"

    _message "Opening Management tomb ... "
    _run open_tomb "${MGMT_TOMB_LABEL}" "${identity}" "${master_pass}"

    _message "Opening SSH tomb ... "
    _run open_tomb "${SSH_TOMB_LABEL}" "${identity}" "${master_pass}"

    _message "Opening PASS tomb ..."
    _run open_tomb "${PASS_TOMB_LABEL}" "${identity}" "${master_pass}"

    _message "Opening Signal tomb ..."
    _run open_tomb "${SIGNAL_TOMB_LABEL}" "${identity}" "${master_pass}"

    exit 0
fi

# Or open a single tomb
open_tomb "${resource}" "${identity}" "${master_pass}"
