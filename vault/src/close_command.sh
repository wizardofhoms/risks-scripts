
resource="${args[resource]}"
# identity="$(_identity_active_or_specified "${args[identity]}")"
IDENTITY="$(_identity_active_or_specified "${args[identity]}")"

# Either only close the GPG keyring and coffin
if [[ "$resource" == "gpg" ]] || [[ "$resource" == "coffin" ]]; then
    _message "Closing coffin and GPG keyring"
    close_coffin "$IDENTITY"
    exit $?
fi

# Or close everything
if [[ "$resource" == "identity" ]]; then
    _message "Closing Signal tomb ..."
    _run close_tomb "$SIGNAL_TOMB_LABEL" "$IDENTITY"

    _message "Closing PASS tomb ..."
    _run close_tomb "$PASS_TOMB_LABEL" "$IDENTITY"

    _message "Closing SSH tomb ..."
    _run close_tomb "$SSH_TOMB_LABEL" "$IDENTITY"

    _message "Closing Management tomb ..."
    _run close_tomb "$MGMT_TOMB_LABEL" "$IDENTITY"

    # Finally, find all other tombs...
    tombs=$(tomb list 2>&1 \
        | sed -n '0~4p' \
        | awk -F" " '{print $(3)}' \
        | rev | cut -c2- | rev | cut -c2-)

    # ... and close them
    while read -r tomb_name ; do
        if [[ -z $tomb_name ]]; then
            continue
        fi

        _message "Closing tomb $tomb_name ..."
        _run tomb close "$tomb_name"
    done <<< "$tombs"

    _message "Closing GPG coffin ..."
    close_coffin "$IDENTITY"
    exit 0
fi

# Or just a tomb
close_tomb "$resource" "$IDENTITY"
exit $?
