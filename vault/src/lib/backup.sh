# make_initial_identity_backup is used at the end of an identity creation process:
# when secret keys are still available in the keyring, as well as some other files,
# we export them, along with a full backup of the hush img.
make_initial_identity_backup () 
{
    local name="$1"
    local PENDRIVE="$2" 
    local passphrase="${3}"
    local gpg_passphrase="${4}"

    local IDENTITY="${name// /_}"       # Used for files
    local MAPPER="pendev"
    local MOUNT_POINT="/tmp/pendrive"

    local uid fingerprint RECIPIENT IDENTITY_GRAVEYARD_PATH BCKDIR

    # Identity and passwords
    _verbose "backup" "Opening identity ${IDENTITY}"
    open_coffin "${IDENTITY}" "${passphrase}"

    # Email recipient and key fingerprints
    uid=$(gpg -K | grep uid | head -n 1)
    RECIPIENT=$(echo "$uid" | grep -E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b")

    fingerprint=$(gpg -K "${RECIPIENT}" | grep fingerprint | head -n 1 | cut -d= -f2 | sed 's/ //g')
    _verbose "backup" "Primary key fingerprint: ${fingerprint}"

    # GPG & Coffin Backup
    if [[ ! -d ${MOUNT_POINT} ]]; then
            _verbose "backup" "Creating mount point directory"
            mkdir ${MOUNT_POINT} &> /dev/null
            _verbose "backup" "Changing directory owner to ${USER}"
            sudo chown "${USER}" ${MOUNT_POINT}
    fi

    _verbose "backup" "Opening LUKS pendrive"
    sudo cryptsetup open --type luks "${PENDRIVE}" ${MAPPER}
    _catch "backup" "Failed to open LUKS pendrive. Aborting"
    sudo mount /dev/mapper/${MAPPER} ${MOUNT_POINT}

    BCKDIR="${MOUNT_POINT}/gpg/${IDENTITY}"
    if [[ ! -d ${BCKDIR} ]]; then
            _verbose "backup" "Creating backup directory for ${IDENTITY}"
            mkdir -p "${BCKDIR}"
    fi

    # GPG backup
    _verbose "backup" "Opening identity ${IDENTITY}"
    _verbose "backup" "Backing up gpg -K output on drive (as gpg-k_output.txt)"
    gpg -K > "${BCKDIR}"/gpg-k_output.txt
    gpg_base_cmd=(gpg --pinentry-mode loopback --batch --no-tty --yes --passphrase-fd 0)

    # Primary key-pair backup
    _verbose "backup" "Backing up primary key-pair (armored)"
    _verbose "backup" "Private key"
    echo "${gpg_passphrase}" | "${gpg_base_cmd[@]}" --export-secret-keys \
        --armor "${fingerprint}" > "${BCKDIR}"/private-primary-keypair.arm.key
    _verbose "backup" "Public key"
    gpg --export --armor "${fingerprint}" > "${BCKDIR}"/public-primary-keypair.arm.key

    # Subkey-pairs backup
    _verbose "backup" "Backing up subkey-pairs (armored)"
    echo "${gpg_passphrase}" | "${gpg_base_cmd[@]}" --export-secret-subkeys \
        "${fingerprint}" > "${BCKDIR}"/private-subkeys.bin.key
    _verbose "backup" "Listing directory (should have 4 files for this identity)"
    _verbose "backup" "$(ls -l "${BCKDIR}")"

    # Graveyard backup 
    _verbose "backup" "Backing tomb files"
    _verbose "backup" "Backing up graveyard to pendrive"
    if [[ ! -d ${MOUNT_POINT}/graveyard ]]; then
            _verbose "backup" "Creating graveyard directory on pendrive"
            mkdir ${MOUNT_POINT}/graveyard &> /dev/null
    fi

    _verbose "backup" "Copying graveyard files"
    _run "backup" sudo chattr -i ${MOUNT_POINT}/graveyard/* \
        || _verbose "backup" "No files in backup/graveyard for which to change immutability properties"
    IDENTITY_GRAVEYARD_PATH=$(get_identity_graveyard "${IDENTITY}" "${passphrase}")
    _run "backup" cp -fR "${IDENTITY_GRAVEYARD_PATH}"/* ${MOUNT_POINT}/graveyard
    _catch "backup" "Failed to copy graveyard files to backup medium"

    # Unmount and close everything before backing the hush image 
    _verbose "backup" "Closing identity ${IDENTITY}"
    close_coffin "${IDENTITY}" "${passphrase}"

    # Hush image backup
    _message "backup" "Backing hush partition"
    _verbose "backup" "Unmounting hush partition"
    _run "backup" risks_hush_umount_command
    if [[ -e ${MOUNT_POINT}/hush.img ]]; then
            sudo chattr -i ${MOUNT_POINT}/hush.img          # Otherwise we can't overwrite
    fi
    sudo dd if=/dev/hush of=${MOUNT_POINT}/hush.img status=progress bs=16M

    # Testing the full backup 
    _verbose "backup" "Testing backup"
    _verbose "backup" "Printing directory tree in backup pendrive"
    _verbose "backup" "$(tree ${MOUNT_POINT})"
    _verbose "backup" "Should have 4 files in gpg/${IDENTITY}/, hush.img and graveyard in root"
    _verbose "backup" "Making all backup files immutable"
    sudo chattr +i ${MOUNT_POINT}/graveyard/*
    sudo chattr +i ${MOUNT_POINT}/hush.img
    sudo chattr +i ${MOUNT_POINT}/gpg/"${IDENTITY}"/*

    _verbose "backup" "Unmounting backup pendrive"
    sudo umount ${MOUNT_POINT}
    _verbose "backup" "Closing LUKS filesystem"
    sudo cryptsetup close ${MAPPER}
    rm -rf "${MOUNT_POINT}"
}
