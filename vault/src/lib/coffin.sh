
# Generates, setup and formats a LUKS partition to be used as a coffin identity files
gen_coffin() 
{
    local key_filename key_file coffin_filename coffin_file coffin_name identity_fs

    # Filenames
    key_filename=$(_encrypt_filename "${IDENTITY}-gpg.key")
    key_file="${HUSH_DIR}/${key_filename}"
    coffin_filename=$(_encrypt_filename "${IDENTITY}-gpg.coffin")
    coffin_file="${GRAVEYARD}/${coffin_filename}"
    coffin_name=$(_encrypt_filename "coffin-${IDENTITY}-gpg")
    identity_fs=$(_encrypt_filename "${IDENTITY}-gpg")

    ## Key
    _verbose "Generating coffin key (compatible with QRCode printing)"
    head --bytes=64 /dev/urandom > "$key_file"
    _verbose "Protecting against deletions"
    sudo chattr +i "$key_file"
    _verbose "Testing immutability of key file"
    _verbose "Output of lsattr:"
    _run lsattr "${HUSH_DIR}"
    _verbose "Output should look like (filename is encrypted):"
    _verbose "—-i———e—- /home/user/.hush/JRklfdjklb334blkfd"

    ## Creation
    _verbose "Creating the coffin container (50MB)"
    _run dd if=/dev/urandom of="$coffin_file" bs=1M count=50

    # Encryption
    _verbose "Laying the coffin LUKS inside the container"
    _run sudo cryptsetup -v -q --cipher aes-xts-plain64 --master-key-file "$key_file" \
            --key-size 512 --hash sha512 --iter-time 5000 --use-random \
            luksFormat "${coffin_file}" "$key_file"
    _catch "Failed to lay setup and format the coffin LUKS filesystem"
    _verbose "Testing coffin detailed output (luksDump)"
    _run sudo cryptsetup luksDump "$coffin_file" 
    _catch "Failed to dump coffin LUKS filesystem"
    _verbose "Normally, we should see the UUID of the coffin, and only one key configured for it"

    ##  Setup 
    _verbose "Opening the coffin for setup"
    _run sudo cryptsetup open --type luks "$coffin_file" "$coffin_name" --key-file "$key_file"
    _catch "Failed to open the coffin LUKS filesystem"

    _verbose "Testing coffin status"
    _run sudo cryptsetup status "$coffin_name" 
    _catch "Failed to get status of coffin LUKS filesystem"

    ## Filesystem
    _verbose "Formatting the coffin filesystem (ext4)"
    _run sudo mkfs.ext4 -m 0 -L "$identity_fs" "/dev/mapper/${coffin_name}"
    _catch "Failed to make ext4 filesystem on coffin partition"
}

# open_coffin requires both an identity name and its corresponding passphrase
open_coffin()
{
    local key_filename          # Encrypted name for the key file
    local key_file              # Absolute path to this key
    local coffin_filename       # Encrypted name of the coffin
    local coffin_file           # Absolute path to the coffin
    local mapper                # LUKS Mapper name
    local mount_dir             # Mount point to use for the coffin mapper

    key_filename=$(_encrypt_filename "${IDENTITY}-gpg.key")
    key_file="${HUSH_DIR}/${key_filename}"
    coffin_filename=$(_encrypt_filename "${IDENTITY}-gpg.coffin")
    coffin_file="${GRAVEYARD}/${coffin_filename}"
    mapper=$(_encrypt_filename "coffin-${IDENTITY}-gpg")

	mount_dir="${HOME}/.gnupg"

	if [[ ! -f "${coffin_file}" ]]; then
		_failure "I'm looking for $coffin_file but no coffin file found in $GRAVEYARD"
	fi

	if is_luks_mounted "/dev/mapper/${mapper}" ; then
		_verbose "Coffin file $coffin_file is already open and mounted"
		return 0
	fi

    if ! is_luks_open "${mapper}"; then
        if ! _run sudo cryptsetup open --type luks "$coffin_file" "$mapper" --key-file "$key_file" ; then
			_failure "I can not open the coffin file $coffin_file"
		fi
	fi

    mkdir -p "${mount_dir}" &> /dev/null

    if ! _run sudo mount -o rw,user /dev/mapper/"${mapper}" "$mount_dir" ; then
		_failure "Coffin file $coffin_file can not be mounted on $mount_dir"
	fi

	_verbose "Coffin $coffin_file has been opened in $mount_dir"

    sudo chown "${USER}" "$mount_dir"
    sudo chmod 0700 "$mount_dir"

    # Set the identity as active, and unlock access to its GRAVEYARD directory
    _set_active_identity "$IDENTITY"

    local identity_dir identity_graveyard

    identity_dir=$(_encrypt_filename "$IDENTITY")
    identity_graveyard="${GRAVEYARD}/$identity_dir"

    # Ask fscrypt to let us access it. While this will actually decrypt the files'
    # names and content, this does not prevent our own obfuscated names; the end
    # result is that all NAMES are obfuscated twice (once us, once fscrypt) and
    # the contents are encrypted once (fscrypt).
    echo "$FILE_ENCRYPTION_KEY" | _run sudo fscrypt unlock "$identity_graveyard" --quiet

    _verbose "Identity directory ($identity_graveyard) is unlocked"
}

close_coffin()
{
    local coffin_filename coffin_file mapper mount_dir

    coffin_filename=$(_encrypt_filename "${IDENTITY}-gpg.coffin")
    coffin_file="${GRAVEYARD}/${coffin_filename}"
    mapper=$(_encrypt_filename "coffin-${IDENTITY}-gpg")

	mount_dir="${HOME}/.gnupg"

    # Gpg-agent is an asshole spawning thousands of processes
    # without anyone to ask for them.... security they said
    gpgconf --kill gpg-agent

	if is_luks_mounted "/dev/mapper/${mapper}" ; then
        if ! _run sudo umount "${mount_dir}" ; then
			_failure "Coffin file ${coffin_file} can not be umounted from ${mount_dir}"
		fi
	fi

    if is_luks_open "$mapper"; then
        if ! _run sudo cryptsetup close /dev/mapper/"${mapper}" ; then
			_failure "Coffin file $coffin_file can not be closed"
		fi
	else
		_verbose "Coffin file $coffin_file is already closed"
		return 0
	fi

    local identity_dir identity_graveyard

    # Lock the identity's graveyard directory
    identity_dir=$(_encrypt_filename "$IDENTITY")
    identity_graveyard="${GRAVEYARD}/${identity_dir}"
    _run sudo fscrypt lock "${identity_graveyard}"

    _set_active_identity # An empty  identity will trigger a wiping of the file 
	_verbose "Coffin file $coffin_file has been closed"
}

list_coffins()
{
	local coffins_num=0
    local coffins

    ls_filtered=(ls -1 --ignore={dmroot,control,hush,pendev} --ignore='tomb*')

    if "${ls_filtered[@]}" &> /dev/null; then
		coffins=$("${ls_filtered[@]}" /dev/mapper)
        coffins_num=$(echo "$coffins" | wc -l)
	fi

	if [[ $coffins_num -gt 0 ]]; then
		_message "Coffins currently opened:"
        echo "$coffins" | xargs
    else
        _message "No opened coffins"
	fi
}
