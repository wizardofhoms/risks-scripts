
# Generates, setup and formats a LUKS partition to be used as a coffin identity files
gen_coffin() 
{
    local IDENTITY="$1" 
    local pass="$2"

    local key_filename key_file coffin_filename coffin_file coffin_name identity_fs

    # Filenames
    key_filename=$(_encrypt_filename "${IDENTITY}" "${IDENTITY}-gpg.key" "$pass")
    key_file="${HUSH_DIR}/${key_filename}"
    coffin_filename=$(_encrypt_filename "${IDENTITY}" "${IDENTITY}-gpg.coffin" "$pass")
    coffin_file="${GRAVEYARD}/${coffin_filename}"
    coffin_name=$(_encrypt_filename "${IDENTITY}" "coffin-${IDENTITY}-gpg" "$pass")
    identity_fs=$(_encrypt_filename "${IDENTITY}" "${IDENTITY}-gpg" "$pass")

    ## Key
    _verbose "coffin" "Generating coffin key (compatible with QRCode printing)"
    get_passphrase "${IDENTITY}" coffin "${pass}" > "$key_file"
    # pwgen -y -s -C 64 > "${key_file}" || _failure "coffin" "Failed to generate coffin key"
    _verbose "coffin" "Protecting against deletions"
    sudo chattr +i "${key_file}"
    _verbose "coffin" "Testing immutability of key file"
    _verbose "coffin" "Output: \n $(lsattr "${HUSH_DIR}")"
    _verbose "coffin" "Output should look like (filename is encrypted):"
    _verbose "coffin" "—-i———e—- /home/user/.hush/JRklfdjklb334blkfd"

    ## Creation
    _verbose "coffin" "Creating the coffin container (50MB)"
    _run "coffin" dd if=/dev/urandom of="${coffin_file}" bs=1M count=50
    _verbose "coffin" "Laying the coffin inside the container"

    # Encryption
    _run 'coffin' sudo cryptsetup -v -q --cipher aes-xts-plain64 --master-key-file "${key_file}" \
            --key-size 512 --hash sha512 --iter-time 5000 --use-random \
            luksFormat "${coffin_file}" "${key_file}"
    _catch "coffin" "Failed to lay setup and format the coffin LUKS filesystem"
    _verbose "coffin" "Testing the coffin"
    _run 'coffin' sudo cryptsetup luksDump "${coffin_file}" 
    _catch "coffin" "Failed to dump coffin LUKS filesystem"
    _verbose "coffin" "Normally, we should see the UUID of the coffin, and only one key configured for it"

    ##  Setup 
    _verbose "coffin" "Opening the coffin for setup"
    _run "coffin" sudo cryptsetup open --type luks "${coffin_file}" "${coffin_name}" --key-file "${key_file}"
    _catch "coffin" "Failed to open the coffin LUKS filesystem"

    _verbose "coffin" "Testing coffin status"
    _run "coffin" sudo cryptsetup status "${coffin_name}" 
    _catch "coffin" "Failed to get status of coffin LUKS filesystem"

    ## Filesystem
    _verbose "coffin" "Formatting the coffin filesystem (ext4)"
    _run "coffin" sudo mkfs.ext4 -m 0 -L "${identity_fs}" "/dev/mapper/${coffin_name}"
    _catch "coffin" "Failed to make ext4 filesystem on coffin partition"
}

# open_coffin requires both an identity name and its corresponding passphrase
open_coffin()
{
	local IDENTITY="${1}"
    local pass="${2}"

    local key_filename key_file coffin_filename coffin_file mapper mount_dir

    key_filename=$(_encrypt_filename "${IDENTITY}" "${IDENTITY}-gpg.key" "$pass")
    key_file="${HUSH_DIR}/${key_filename}"
    coffin_filename=$(_encrypt_filename "${IDENTITY}" "${IDENTITY}-gpg.coffin" "$pass")
    coffin_file="${GRAVEYARD}/${coffin_filename}"
    mapper=$(_encrypt_filename "${IDENTITY}" "coffin-${IDENTITY}-gpg" "$pass")

	mount_dir="${HOME}/.gnupg"

	if [[ ! -f "${coffin_file}" ]]; then
		_failure "coffin" "I'm looking for ${coffin_file} but no coffin file found in ${GRAVEYARD}"
	fi

	if is_luks_mounted "/dev/mapper/${mapper}" ; then
		_verbose 'coffin' "Coffin file ${coffin_file} is already open and mounted"
		return 0
	fi

    if ! is_luks_open "${mapper}"; then
        if ! _run 'coffin' sudo cryptsetup open --type luks "${coffin_file}" "${mapper}" --key-file "${key_file}" ; then
			_failure "coffin" "I can not open the coffin file ${coffin_file}"
		fi
	fi

    mkdir -p "${mount_dir}" &> /dev/null

    if ! _run 'coffin' sudo mount -o rw,user /dev/mapper/"${mapper}" "${mount_dir}" ; then
		_failure "coffin" "Coffin file ${coffin_file} can not be mounted on ${mount_dir}"
	fi

	_verbose "identity" "Coffin ${coffin_file} has been opened in ${mount_dir}"

    sudo chown "${USER}" "${mount_dir}"
    sudo chmod 0700 "${mount_dir}"

    # Set the identity as active, and unlock access to its GRAVEYARD directory
    _set_identity "${IDENTITY}"

    GRAVEYARD_DIRECTORY_ENC=$(_encrypt_filename "${IDENTITY}" "${IDENTITY}" "${pass}")
    IDENTITY_GRAVEYARD_PATH="${GRAVEYARD}/${GRAVEYARD_DIRECTORY_ENC}"

    # Ask fscrypt to let us access it. While this will actually decrypt the files'
    # names and content, this does not prevent our own obfuscated names; the end
    # result is that all NAMES are obfuscated twice (once us, once fscrypt) and
    # the contents are encrypted once (fscrypt).
    echo "${pass}" | _run "graveyard" sudo fscrypt unlock "${IDENTITY_GRAVEYARD_PATH}" --quiet

    _verbose "graveyard" "Identity directory (${IDENTITY_GRAVEYARD_PATH}) is unlocked"
}

close_coffin()
{
    local IDENTITY="${1}"
    local pass="${2}"

    local coffin_filename coffin_file mapper mount_dir

    coffin_filename=$(_encrypt_filename "${IDENTITY}" "${IDENTITY}-gpg.coffin" "$pass")
    coffin_file="${GRAVEYARD}/${coffin_filename}"
    mapper=$(_encrypt_filename "${IDENTITY}" "coffin-${IDENTITY}-gpg" "$pass")

	mount_dir="${HOME}/.gnupg"

    # Gpg-agent is an asshole spawning thousands of processes
    # without anyone to ask for them.... security they said
    gpgconf --kill gpg-agent

	if is_luks_mounted "/dev/mapper/${mapper}" ; then
        if ! _run 'coffin' sudo umount "${mount_dir}" ; then
			_failure "risks" "Coffin file ${coffin_file} can not be umounted from ${mount_dir}"
		fi
	fi

    if is_luks_open "${mapper}"; then
        if ! _run 'coffin' sudo cryptsetup close /dev/mapper/"${mapper}" ; then
			_failure "risks" "Coffin file ${coffin_file} can not be closed"
		fi
	else
		_verbose 'coffin' "Coffin file ${coffin_file} is already closed"
		return 0
	fi

    # Lock the identity's graveyard directory
    GRAVEYARD_DIRECTORY_ENC=$(_encrypt_filename "${IDENTITY}" "${IDENTITY}" "${pass}")
    IDENTITY_GRAVEYARD_PATH="${GRAVEYARD}/${GRAVEYARD_DIRECTORY_ENC}"
    _run "fscrypt" sudo fscrypt lock "${IDENTITY_GRAVEYARD_PATH}"

    _set_identity '' # An empty  identity will trigger a wiping of the file 
	_verbose "identity" "Coffin file ${coffin_file} has been closed"
}

list_coffins()
{
	local coffins_num=0
    local coffins

	if ls -1 /dev/mapper/coffin-* &> /dev/null; then
		coffins=$(ls -1 /dev/mapper/coffin-* | awk -F- {'print $2'})
        coffins_num=$(echo "${coffins}" | wc -l)
	fi

	if [[ ${coffins_num} -gt 0 ]]; then
		_message "risks" "Coffins currently open:"
        echo "${coffins}" | xargs
	fi
}
