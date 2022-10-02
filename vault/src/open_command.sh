# The open_command file is essentially a wrapper around several library
# functions, depending on the type of store the user wants to open.

resource="${args[resource]}"

_set_identity "${args[identity]}"

# Either only open the GPG keyring.
if [[ "$resource" == "gpg" ]] || [[ "$resource" == "coffin" ]]; then
    # We need to identity argument to be non-nil
    if [[ -z $IDENTITY ]]; then
        _failure "The IDENTITY argument was not specified"
    fi

    _message "Opening coffin and mounting GPG keyring"

    open_coffin
    exit $?
fi

# Then derive the gpg pass phrase from it, with one-time use,
# needed for all tombs, no matter how many.
GPG_PASS=$(get_passphrase "$GPG_TOMB_LABEL")
echo -n "$GPG_PASS" | xclip -loops 1 -selection clipboard
_warning "GPG passphrase copied to clipboard with one-time use only"

# Bulk load
if [[ "$resource" == "identity" ]]; then

    _message "Opening coffin and mounting GPG keyring"
    open_coffin

    _message "Opening Management tomb ... "
    _run open_tomb "$MGMT_TOMB_LABEL"

    _message "Opening SSH tomb ... "
    _run open_tomb "$SSH_TOMB_LABEL"

    _message "Opening PASS tomb ..."
    _run open_tomb "$PASS_TOMB_LABEL"

    _message "Opening Signal tomb ..."
    _run open_tomb "$SIGNAL_TOMB_LABEL"

    exit 0
fi

# Or open a single tomb
open_tomb "$resource" "$IDENTITY"
