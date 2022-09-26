
get_tomb_mapper()
{
	ls -1 /dev/mapper/tomb.* &> /dev/null
	if [[ $? -eq 0 ]]; then
		ls -1 /dev/mapper/tomb.* | grep ${1}
	else
		echo "none"
	fi
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

    # Filenames
    local TOMBID="${IDENTITY}-${RESOURCE}"
    local TOMB_FILE_ENC=$(_encrypt_filename "${IDENTITY}" "${TOMBID}.tomb" ${passphrase})
    local TOMB_FILE="${GRAVEYARD}/${TOMB_FILE_ENC}"
    local TOMB_KEY_FILE_ENC=$(_encrypt_filename "${IDENTITY}" "${TOMBID}.key" ${passphrase})
    local TOMB_KEY_FILE="${HUSH_DIR}/${TOMB_KEY_FILE_ENC}"
    
	local mapper=$(get_tomb_mapper ${TOMBID})

    # Some funtions will call this function while not wanting output
    # if the tomb is already open. Any non-nil value means true.
    local SILENT_IF_OPEN=$3

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
		if is_luks_mounted "/dev/mapper/tomb.${TOMBID}" ; then
            if [[ -z ${SILENT_IF_OPEN} ]]; then
			    echo "Tomb ${TOMBID} is already open and mounted"
            fi
			return 0
		fi
	fi

	if [[ ! -f "${TOMB_FILE}" ]]; then
		echo "No tomb file ${TOMB_FILE} found"
		return 2
	fi

    if [[ ! -f "${TOMB_KEY_FILE}" ]]; then
        echo "No key file ${TOMB_KEY_FILE} found"
		return 2
	fi

	# checks if the gpg coffin is mounted
    local COFFIN_NAME=$(_encrypt_filename "${IDENTITY}" "coffin-${IDENTITY}-gpg" "$passphrase")
	if ! is_luks_mounted "/dev/mapper/${COFFIN_NAME}" ; then
		open_coffin ${IDENTITY} ${passphrase} 
	fi

	if [[ ! -d ${mount_dir} ]]; then
		mkdir -p ${mount_dir}
	fi

	tomb open -g -k "${TOMB_KEY_FILE}" "${TOMB_FILE}" "${mount_dir}"

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
    local IDENTITY="$(_identity_active_or_specified ${2})"

    local FULL_LABEL="${IDENTITY}-${RESOURCE}"

	if ! get_tomb_mapper ${IDENTITY}-${RESOURCE} &> /dev/null ; then
		_message "Tomb ${IDENTITY}-${RESOURCE} is already closed"
		return 0
	fi

        # If the concatenated string is too long, cut it to 16 chars
        if [[ ${#FULL_LABEL} -ge 16 ]]; then
                FULL_LABEL=${FULL_LABEL:0:16}
        fi

        # Then close it
	tomb close ${FULL_LABEL}

	if [[ "${RESOURCE}" == "ssh" ]]; then
		ssh-add -D
	fi

}

