
# Upon unlocking a given identity, sets the name as an ENV 
# variable that we can use in further functions and commands.
# $1 - The name to use. If empty, just resets the identity.
_set_active_identity ()
{
    # If the identity is empty, wipe the identity file
    if [[ -z ${1} ]] && [[ -e ${RISKS_IDENTITY_FILE} ]]; then
        identity=$(cat "${RISKS_IDENTITY_FILE}")
        _run wipe -s -f -P 10 "${RISKS_IDENTITY_FILE}" || _warning "Failed to wipe identity file !"

        _verbose "Identity '${identity}' is now inactive, (name file deleted)"
        _message "Identity '${identity}' is now INACTIVE"
        return
    fi

    
    # If we don't have a file containing the 
    # identity name, populate it.
    if [[ ! -e ${RISKS_IDENTITY_FILE} ]]; then
        print "$1" > "${RISKS_IDENTITY_FILE}"
	fi

    _verbose "Identity '${1}' is now active (name file written)"
    _message "Identity '${1}' is now ACTIVE"
}

# Returns 0 if an identity is unlocked, 1 if not.
_identity_active () 
{
    local identity

    if [[ ! -e "${RISKS_IDENTITY_FILE}" ]]; then
        return 1
	fi

    identity=$(cat "${RISKS_IDENTITY_FILE}")
    if [[ -z ${identity} ]]; then
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
    if [[ -z "${1}" ]] ; then
        if ! _identity_active ; then
            return 1
        fi
    fi

    # Print the identity
    if [[ -n "${1}" ]]; then
        print "${1}" && return
    fi

    print "$(cat "${RISKS_IDENTITY_FILE}")"
}

# _set_identity is used to propagate our various IDENTITY related variables
# so that all functions that will be subsequently called can access them.
#
# This function also takes care of checking if there is already an active
# identity that should be used, in case the argument is empty or none.
#
# $1 - The identity to use.
_set_identity () {
    local identity="$1"

    # This will throw an error if we don't have an identity from any source.
    IDENTITY=$(_identity_active_or_specified "$identity")
    _catch "Command requires either an identity to be active or given as argument"

    # Then set the file encryption key for for it.
    FILE_ENCRYPTION_KEY=$(_set_file_encryption_key "$IDENTITY")
}
