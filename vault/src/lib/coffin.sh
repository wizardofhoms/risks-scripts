
# Generates, setup and formats a LUKS partition to be used as a coffin identity files
gen_coffin() 
{
    local IDENTITY="$1" 
    local pass="$2"

    # Filenames
    local key_filename=$(_encrypt_filename ${IDENTITY} "${IDENTITY}-gpg.key" "$pass")
    local key_file="${HUSH_DIR}/${key_filename}"
    local coffin_filename=$(_encrypt_filename ${IDENTITY} "${IDENTITY}-gpg.coffin" "$pass")
    local coffin_file="${GRAVEYARD}/${coffin_filename}"
    local coffin_name=$(_encrypt_filename ${IDENTITY} "coffin-${IDENTITY}-gpg" "$pass")
    local identity_fs=$(_encrypt_filename ${IDENTITY} "${IDENTITY}-gpg" "$pass")

    ## Key
    _verbose "coffin" "Generating coffin key (compatible with QRCode printing)"
    pwgen -y -s -C 64 > ${key_file} || _failure "coffin" "Failed to generate coffin key"
    _verbose "coffin" "Protecting against deletions"
    sudo chattr +i ${key_file}
    _verbose "coffin" "Testing immutability of key file"
    lsattr ${HUSH_DIR}
    echo
    _verbose "coffin" "Output should look like (filename is encrypted):"
    echo
    echo "—-i———e—- /home/user/.hush/JRklfdjklb334blkfd"
    echo

    ## Creation
    _verbose "coffin" "Creating the coffin container (50MB)"
    if [[ ! -d ${GRAVEYARD} ]]; then
            _verbose "coffin" "Creating directory ${GRAVEYARD}"
            mkdir -p ${GRAVEYARD}
    fi
    dd if=/dev/urandom of=${coffin_file} bs=1M count=50
    _verbose "coffin" "Laying the coffin inside the container"
    sudo cryptsetup -v -q --cipher aes-xts-plain64 --master-key-file ${key_file} \
            --key-size 512 --hash sha512 --iter-time 5000 --use-random \
            luksFormat ${coffin_file} ${key_file} \
            || _failure "coffin" "Failed to lay setup and format the coffin LUKS filesystem"
    _verbose "coffin" "Testing the coffin"
    sudo cryptsetup luksDump ${coffin_file} || _failure "coffin" "Failed to dump coffin LUKS filesystem"
    echo
    _warning "coffin" "Normally, we should see the UUID of the coffin, and only key configured for it" -b
    echo

    ##  Setup 
    _success "coffin" "5) Setup"
    _verbose "coffin" "Opening the coffin for setup"
    sudo cryptsetup open --type luks ${coffin_file} ${coffin_name} --key-file ${key_file} \
            || _failure "coffin" "Failed to open the coffin LUKS filesystem"

    _verbose "coffin" "Testing coffin status"
    sudo cryptsetup status ${coffin_name} || _warning "coffin" "Failed to get status of coffin LUKS filesystem"
    echo

    ## Filesystem
    _verbose "coffin" "Formatting the coffin filesystem (ext4)"
    sudo mkfs.ext4 -m 0 -L ${identity_fs} /dev/mapper/${coffin_name} \
            || _failure "coffin" "Failed to make ext4 filesystem on coffin partition"
}

# open_coffin requires both an identity name and its corresponding passphrase
open_coffin()
{
	local IDENTITY="${1}"
    local pass="${2}"

    local key_filename=$(_encrypt_filename ${IDENTITY} "${IDENTITY}-gpg.key" "$pass")
    local key_file="${HUSH_DIR}/${key_filename}"
    local coffin_filename=$(_encrypt_filename ${IDENTITY} "${IDENTITY}-gpg.coffin" "$pass")
    local coffin_file="${GRAVEYARD}/${coffin_filename}"
    local mapper=$(_encrypt_filename ${IDENTITY} "coffin-${IDENTITY}-gpg" "$pass")

	local mount_dir="${HOME}/.gnupg"

	if [[ ! -f "${coffin_file}" ]]; then
		echo "I'm looking for ${coffin_file} but no coffin file found in ${GRAVEYARD}"
		exit 1
	fi

	if is_luks_mounted "/dev/mapper/${mapper}" ; then
		echo "Coffin file ${coffin_file} is already open and mounted"
		return 0
	fi

	if ! is_luks_open ${mapper}; then
		if ! sudo cryptsetup open --type luks ${coffin_file} ${mapper} --key-file ${key_file} ; then
			echo "I can not open the coffin file ${coffin_file}"
			exit 1
		fi
	fi

	mkdir -p ${mount_dir} &> /dev/null

	if ! sudo mount -o rw,user /dev/mapper/${mapper} ${mount_dir} ; then
		echo "Coffin file ${coffin_file} can not be mounted on ${mount_dir}"
		exit 1
	fi

	sudo chown ${USER} ${mount_dir}
	sudo chmod 0700 ${mount_dir}
    _set_identity ${IDENTITY} # And set the active identity file
	_verbose "identity" "Coffin ${coffin_file} has been opened in ${mount_dir}"
}

close_coffin()
{
    local IDENTITY="${1}"
    local pass="${2}"

    local coffin_filename=$(_encrypt_filename ${IDENTITY} "${IDENTITY}-gpg.coffin" "$pass")
    local coffin_file="${GRAVEYARD}/${coffin_filename}"
    local mapper=$(_encrypt_filename ${IDENTITY} "coffin-${IDENTITY}-gpg" "$pass")

	local mount_dir="${HOME}/.gnupg"

    # Gpg-agent is an asshole spawning thousands of processes
    # without anyone to ask for them.... security they said
    gpgconf --kill gpg-agent

	if is_luks_mounted "/dev/mapper/${mapper}" ; then
		if ! sudo umount ${mount_dir} ; then
			echo "Coffin file ${coffin_file} can not be umounted from ${mount_dir}"
			exit 1
		fi
	fi

	if is_luks_open ${mapper}; then
		if ! sudo cryptsetup close /dev/mapper/${mapper} ; then
			echo "Coffin file ${coffin_file} can not be closed"
			exit 1
		fi
	else
		echo "Coffin file ${coffin_file} is already closed"
		return 0
	fi

    _set_identity '' # An empty  identity will trigger a wiping of the file 
	_verbose "identity" "Coffin file ${coffin_file} has been closed"
}

list_coffins()
{
	local coffins_num=0

	if ls -1 /dev/mapper/coffin-* &> /dev/null; then
		local coffins=$(ls -1 /dev/mapper/coffin-*| awk -F- {'print $2'})
		local coffins_num=$(echo ${coffins} | wc -l)
	fi

	if [[ ${coffins_num} -gt 0 ]]; then
		_message "risks" "Coffins currently open:"
		echo $(echo ${coffins} | xargs)
	fi
}

