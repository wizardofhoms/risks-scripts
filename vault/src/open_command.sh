# The open_command file is essentially a wrapper around several library
# functions, depending on the type of store the user wants to open.

resource="${args[resource]}"
# identity="${args[identity]}" # May be empty
IDENTITY="$(_identity_active_or_specified "${args[identity]}")"
MASTER_PASS=$(get_passphrase "$IDENTITY")

# Either only open the GPG keyring.
if [[ "$resource" == "gpg" ]] || [[ "$resource" == "coffin" ]]; then
    # We need to identity argument to be non-nil
    if [[ -z $IDENTITY ]]; then
        _failure "The IDENTITY argument was not specified"
    fi

    _message "Opening coffin and mounting GPG keyring"

    # IDENTITY="$(_identity_active_or_specified "$identity")"
    # MASTER_PASS=$(get_passphrase "$IDENTITY")

    open_coffin "$IDENTITY"
    exit $?
fi

# Or we either open an entire identity or some tomb,
# and then the identity argument is optional, since
# we might have one already active.
# IDENTITY="$(_identity_active_or_specified "$identity")"
# MASTER_PASS=$(get_passphrase "$IDENTITY")

# Then derive the gpg pass phrase from it, with one-time use
GPG_PASS=$(get_passphrase "$IDENTITY" "$GPG_TOMB_LABEL" "$MASTER_PASS")
echo -n "$GPG_PASS" | xclip -loops 1 -selection clipboard
_warning "GPG passphrase copied to clipboard with one-time use only"

# Bulk load
if [[ "$resource" == "identity" ]]; then

    _message "Opening coffin and mounting GPG keyring"
    open_coffin "$IDENTITY"

    _message "Opening Management tomb ... "
    _run open_tomb "$MGMT_TOMB_LABEL" "$IDENTITY"

    _message "Opening SSH tomb ... "
    _run open_tomb "$SSH_TOMB_LABEL" "$IDENTITY"

    _message "Opening PASS tomb ..."
    _run open_tomb "$PASS_TOMB_LABEL" "$IDENTITY"

    _message "Opening Signal tomb ..."
    _run open_tomb "$SIGNAL_TOMB_LABEL" "$IDENTITY"

    exit 0
fi

# Or open a single tomb
open_tomb "$resource" "$IDENTITY"
