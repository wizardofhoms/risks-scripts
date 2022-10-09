
# Upon unlocking a given identity, sets the name as an ENV 
# variable that we can use in further functions and commands.
# $1 - The name to use. If empty, just resets the identity.
_set_active_identity ()
{
    # If the identity is empty, wipe the identity file
    if [[ -z ${1} ]] && [[ -e ${RISK_IDENTITY_FILE} ]]; then
        identity=$(cat "${RISK_IDENTITY_FILE}")
        rm "${RISK_IDENTITY_FILE}" || _warning "Failed to wipe identity file !"

        _verbose "Identity '${identity}' is now inactive, (name file deleted)"
        _message "Identity '${identity}' is now INACTIVE"
        return
    fi

    
    # If we don't have a file containing the 
    # identity name, populate it.
    if [[ ! -e ${RISK_IDENTITY_FILE} ]]; then
        print "$1" > "${RISK_IDENTITY_FILE}"
	fi

    _verbose "Identity '${1}' is now active (name file written)"
    _message "Identity '${1}' is now ACTIVE"
}

# Returns 0 if an identity is unlocked, 1 if not.
_identity_active () 
{
    local identity

    active_identity=$(qvm-run --pass-io "$VAULT_VM" 'cat .identity' 2>/dev/null)
    if [[ -z "${active_identity}" ]]; then
        return 1
	fi

    return 0
}

# Given an argument potentially containing the active identity, checks
# that either an identity is active, or that the argument is not empty.
# $1 - An identity name
# Exits the program if none is specified, or echoes the identity if found.
# Returns:
# 0 - Identity is non-nil, provided either from arg or by the active
# 1 - None have been given
_identity_active_or_specified ()
{
    local active_identity

    if [[ -z "${1}" ]] ; then
        active_identity=$(qvm-run --pass-io "$VAULT_VM" 'cat .identity' 2>/dev/null)
        if [[ -z "${active_identity}" ]]; then
            return 1
        fi
    fi

    # Print the identity
    if [[ -n "${1}" ]]; then
        print "${1}" && return
    fi

    print "$active_identity"
}

# _set_identity is used to propagate our various IDENTITY related variables
# so that all functions that will be subsequently called can access them.
#
# This function also takes care of checking if there is already an active
# identity that should be used, in case the argument is empty or none.
#
# $1 - The identity to use.
_set_identity () 
{
    local identity="$1"

    # This will throw an error if we don't have an identity from any source.
    IDENTITY=$(_identity_active_or_specified "$identity")
    _catch "Command requires either an identity to be active or given as argument"

    # Set the identity directory
    IDENTITY_DIR="${RISK_IDENTITIES_DIR}/${IDENTITY}"
}

# check that no identity is active in the vault, and fail if there is.
check_no_active_identity ()
{
    active_identity=$(qvm-run --pass-io "$VAULT_VM" 'cat .identity' 2>/dev/null)
    if [[ -n $active_identity ]]; then
        # It might be the same
        if [[ $active_identity == "$1" ]]; then
            _message "Identity $1 is already active"
            exit 0
        fi

        _failure "Identity $active_identity is active. Close/slam/fold it and rerun this command"
    fi
}

# Get the default VM label/color for an identity
get_identity_label ()
{
    cat "${IDENTITY_DIR}/vm_label" 2>/dev/null
}

# _identity_proxies returns an array of proxy VMs 
# (VPNs and TOR gateways for the current identity)
_identity_proxies ()
{
    [[ -f "${IDENTITY_DIR}/proxy_vms" ]] || return
    read -d '' -r -A proxies <"${IDENTITY_DIR}/proxy_vms"
    echo "${proxies[@]}"
}

# returns all identity VMs that are not gateways/proxies,
# but are potentially (most of the time) accessing network
# from one or more of these gateways.
_identity_client_vms ()
{
    [[ -f "${IDENTITY_DIR}/client_vms" ]] || return
    read -d '' -r -A clients <"${IDENTITY_DIR}/client_vms"
    echo "${clients[@]}"
}

# returns all identity VMs that are not gateways/proxies,
# but are potentially (most of the time) accessing network
# from one or more of these gateways.
_identity_autostart_vms ()
{
    [[ -f "${IDENTITY_DIR}/autostart_vms" ]] || return
    read -d '' -r -A clients <"${IDENTITY_DIR}/autostart_vms"
    echo "${clients[@]}"
}
