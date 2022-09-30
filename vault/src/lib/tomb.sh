
get_tomb_mapper()
{
	if ls -1 /dev/mapper/tomb.* &> /dev/null ;  then
        ls -1 /dev/mapper/tomb.* | grep "${1}"
	else
		echo "none"
	fi
}

# new_graveyard generates a private directory in the
# graveyard for a given identity, with fscrypt support.
new_graveyard ()
{
    local IDENTITY="$1"
    local passphrase="$2"

    local GRAVEYARD_DIRECTORY_ENC IDENTITY_GRAVEYARD_PATH

    # Always make sure the root graveyard directory exists
    if [[ ! -d ${GRAVEYARD} ]]; then
            _verbose "Creating directory ${GRAVEYARD}"
            mkdir -p "${GRAVEYARD}"
    fi

    # The directory name in cleartext is simply the identity name
    GRAVEYARD_DIRECTORY_ENC=$(_encrypt_filename "${IDENTITY}" "${IDENTITY}" "${passphrase}")
    IDENTITY_GRAVEYARD_PATH="${GRAVEYARD}/${GRAVEYARD_DIRECTORY_ENC}"

    # Make the directory
    _verbose "Creating identity graveyard directory"
    mkdir -p "${IDENTITY_GRAVEYARD_PATH}"

    # And setup fscrypt protectors on it.
    _verbose "Setting up fscrypt protectors on directory"
    echo "${passphrase}" | sudo fscrypt encrypt "${IDENTITY_GRAVEYARD_PATH}" \
       --quiet --source=custom_passphrase --name="${GRAVEYARD_DIRECTORY_ENC}"
}

# get_identity_graveyard returns the path to an identity's graveyard directory,
# and decrypts (gives access to) this directory, since this function was called
# because we need some resource stored within.
get_identity_graveyard ()
{
    local IDENTITY="$1"
    local passphrase="$2"

    local GRAVEYARD_DIRECTORY_ENC IDENTITY_GRAVEYARD_PATH

    # Compute the directory names and absolute paths
    GRAVEYARD_DIRECTORY_ENC=$(_encrypt_filename "${IDENTITY}" "${IDENTITY}" "${passphrase}")
    IDENTITY_GRAVEYARD_PATH="${GRAVEYARD}/${GRAVEYARD_DIRECTORY_ENC}"

    print "${IDENTITY_GRAVEYARD_PATH}"
}

# Generates a new tomb for a given identity
new_tomb()
{
    local LABEL="$1"
    local SIZE="$2"
    local IDENTITY="$3"
    local passphrase="$4"
    
    local TOMBID TOMBID_ENC TOMB_FILE 
    local TOMB_KEY_FILE_ENC TOMB_KEY_FILE
    local uid RECIPIENT

    # Filenames
    TOMBID="${IDENTITY}-${LABEL}"
    TOMBID_ENC=$(_encrypt_filename "${IDENTITY}" "${TOMBID}" "${passphrase}")

    TOMB_KEY_FILE_ENC=$(_encrypt_filename "${IDENTITY}" "${TOMBID}.key" "${passphrase}")
    TOMB_KEY_FILE="${HUSH_DIR}/${TOMB_KEY_FILE_ENC}"
    
    IDENTITY_GRAVEYARD_PATH=$(get_identity_graveyard "${IDENTITY}" "${passphrase}")
    TOMB_FILE="${IDENTITY_GRAVEYARD_PATH}/${TOMBID_ENC}.tomb"

    # First make sure GPG keyring is accessible
    _verbose "Opening identity ${IDENTITY}"
    open_coffin "${IDENTITY}" "${passphrase}"

    # And get the email recipient
    uid=$(gpg -K | grep uid | head -n 1)
    RECIPIENT=$(echo "$uid" | grep -E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b")

    # Then dig
    _verbose "Digging tomb in ${TOMB_FILE}"
    tomb dig -s "${SIZE}" "${TOMB_FILE}" 
    _catch "Failed to dig tomb. Aborting"
    _run risks_hush_rw_command 
    _verbose "Forging tomb key and making it immutable"
    tomb forge -g -r "${RECIPIENT}" "${TOMB_KEY_FILE}" 
    _catch "Failed to forge keys. Aborting"
    sudo chattr +i "${TOMB_KEY_FILE}" 
    _verbose "Locking tomb with key"
    tomb lock -g -k "${TOMB_KEY_FILE}" "${TOMB_FILE}" 
    _catch "Failed to lock tomb. Aborting"
    _run risks_hush_ro_command
}

# open_tomb requires a cleartext resource name that the function will encrypt to resolve the correct tomb file.
# The name is both used as a mount directory, as well as to determine when some special tombs need to be mounted
# on non-standard mount points, like gpg/ssh.
# $1 - Name of the tomb
# $2 - Identity
# $3 - Passphrase
open_tomb()
{
	local RESOURCE="${1}"
    local IDENTITY="${2}"
    local passphrase=${3}

    local TOMBID TOMBID_ENC TOMB_FILE 
    local TOMB_KEY_FILE_ENC TOMB_KEY_FILE
    local mapper

    # Filenames
    TOMBID="${IDENTITY}-${RESOURCE}"
    TOMBID_ENC=$(_encrypt_filename "${IDENTITY}" "${TOMBID}" "${passphrase}")

    TOMB_KEY_FILE_ENC=$(_encrypt_filename "${IDENTITY}" "${TOMBID}.key" "${passphrase}")
    TOMB_KEY_FILE="${HUSH_DIR}/${TOMB_KEY_FILE_ENC}"

    IDENTITY_GRAVEYARD_PATH=$(get_identity_graveyard "${IDENTITY}" "${passphrase}")
    TOMB_FILE="${IDENTITY_GRAVEYARD_PATH}/${TOMBID_ENC}.tomb"
    
    mapper=$(get_tomb_mapper "${TOMBID_ENC}")

	case ${RESOURCE} in
		gpg)
			local mount_dir="${HOME}/.gnupg"
		;;
		pass)
			local mount_dir="${HOME}/.password-store"
		;;
		ssh)
			local mount_dir="${HOME}/.ssh"
		;;
		mgmt)
			local mount_dir="${HOME}/.tomb/mgmt"
		;;
		*)
			local mount_dir="${HOME}/.tomb/${RESOURCE}"
		;;
	esac

	if [[ "${mapper}" != "none" ]]; then
        if is_luks_mounted "/dev/mapper/tomb.${TOMBID_ENC}" ; then
            _verbose "Tomb ${TOMBID} is already open and mounted"
			return 0
		fi
	fi

	if [[ ! -f "${TOMB_FILE}" ]]; then
		_warning "No tomb file ${TOMB_FILE} found"
		return 2
	fi

    if [[ ! -f "${TOMB_KEY_FILE}" ]]; then
        _warning "No key file ${TOMB_KEY_FILE} found"
		return 2
	fi

	# checks if the gpg coffin is mounted
    local COFFIN_NAME
    COFFIN_NAME=$(_encrypt_filename "${IDENTITY}" "coffin-${IDENTITY}-gpg" "$passphrase")
	if ! is_luks_mounted "/dev/mapper/${COFFIN_NAME}" ; then
        open_coffin "${IDENTITY}" "${passphrase}" 
	fi

    # Make the mount point directory if needed
	if [[ ! -d ${mount_dir} ]]; then
        mkdir -p "${mount_dir}"
	fi

    # And finally open the tomb
	tomb open -g -k "${TOMB_KEY_FILE}" "${TOMB_FILE}" "${mount_dir}"
    _catch "Failed to open tomb"

    # Either add the only SSH key, or all of them if we have a script
	if [[ "${RESOURCE}" == "ssh" ]]; then
        local ssh_add_script="${HOME}/.ssh/ssh-add"
        if [[ -e ${ssh_add_script} ]]; then
            ${ssh_add_script}
        else
            ssh-add
        fi
	fi
}

close_tomb()
{
	local RESOURCE="${1}"
    local IDENTITY="${2}"
    local passphrase=${3}

    # Filenames
    # local FULL_LABEL="${IDENTITY}-${RESOURCE}"
    TOMBID="${IDENTITY}-${RESOURCE}"
    TOMBID_ENC=$(_encrypt_filename "${IDENTITY}" "${TOMBID}" "${passphrase}")

    if ! get_tomb_mapper "${TOMBID_ENC}" &> /dev/null ; then
    # if ! get_tomb_mapper "${IDENTITY}"-"${RESOURCE}" &> /dev/null ; then
		_verbose "Tomb ${IDENTITY}-${RESOURCE} is already closed"
		return 0
	fi

    # If the concatenated string is too long, cut it to 16 chars
    if [[ ${#TOMBID_ENC} -ge 16 ]]; then
        TOMBID_ENC=${TOMBID_ENC:0:16}
    fi

    # Then close it
    tomb close "${TOMBID_ENC}"

    # And delete the directory if it's not a builtin
	case ${RESOURCE} in
		gpg|pass|ssh|signal|mgmt)
            # Ignore those
		;;
		*)
            rm -rf "${HOME}/.tomb/${RESOURCE}"
		;;
	esac

    # SSH tombs must all delete all SSH identities from the agent
	if [[ "${RESOURCE}" == "ssh" ]]; then
		_run ssh-add -D
	fi
}

