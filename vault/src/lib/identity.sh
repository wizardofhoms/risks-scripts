
# The identity used by RISKS, set when one of the identities 
# is unlocked, and reset when this identity is closed.
local RISKS_IDENTITY_FILE="${HOME}/.identity"

# Upon unlocking a given identity, sets the name as an ENV 
# variable that we can use in further functions and commands.
# $1 - The name to use. If empty, just resets the identity.
_set_identity ()
{
    # If the identity is empty, wipe the identity file
    if [[ -z ${1} ]] && [[ -e ${RISKS_IDENTITY_FILE} ]]; then
        wipe -s -f -P 10 ${RISKS_IDENTITY_FILE}
        _verbose "risks" "Identity '${1}' is now inactive, (name file deleted)"
        return
    fi

    
    # If we don't have a file containing the 
    # identity name, populate it.
    if [[ ! -e ${RISKS_IDENTITY_FILE} ]]; then
        print "$1" > ${RISKS_IDENTITY_FILE}
	fi

    _verbose "risks" "Identity '${1}' is now active (name file written)"
}

# Returns 0 if an identity is unlocked, 1 if not.
_identity_active () 
{
    if [[ ! -e ${RISKS_IDENTITY_FILE} ]]; then
        return 1
	fi

    local identity=$(cat ${RISKS_IDENTITY_FILE})
    if [[ -z ${identity} ]]; then
        return 1
    fi

    return 0
}

# Given an argument potentially containing the active identity, checks
# that either an identity is active, or that the argument is not empty.
# $1 - An identity name
# Exits the program if none is specified, or echoes the identity if found.
_identity_active_or_specified ()
{
    if [[ -z ${1} ]] && [[ ! _identity_active ]]; then
        _failure "identity" "Command requires either an identity to be unlocked.\n \
            Please use 'risks open identity <name>' or 'risks open gpg <name>' first."
    fi

    # Print the identity
    if [[ -z ${1} ]]; then
        print "${1}" && return
    fi
    print "$(cat ${RISKS_IDENTITY_FILE})"
}