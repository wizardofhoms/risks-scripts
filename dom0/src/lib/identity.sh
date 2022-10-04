
# check that no identity is active in the vault, and fail if there is.
check_no_active_identity ()
{
    active_identity=$(qvm-run --pass-io "$VAULT_VM" 'cat .identity' 2>/dev/null)
    if [[ -n $active_identity ]]; then
        # It might be the same
        if [[ $active_identity == $1 ]]; then
            _message "Identity $1 is already active"
            exit 0
        fi

        _failure "Identity $active_identity is active. Close/slam/fold it and rerun this command"
    fi
}
