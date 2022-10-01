# make_initial_identity_backup is used at the end of an identity creation process:
# when secret keys are still available in the keyring, as well as some other files,
# we export them, along with a full backup of the hush img.
make_initial_identity_backup () 
{
    local IDENTITY="$1"
    local PENDRIVE="$2" 

    local MAPPER="pendev"
    local MOUNT_POINT="/tmp/pendrive"

    local uid fingerprint RECIPIENT IDENTITY_GRAVEYARD_PATH BCKDIR

    # Identity and passwords
    _verbose "Opening identity $IDENTITY"
    open_coffin "$IDENTITY"

    # Email recipient and key fingerprints
    uid=$(gpg -K | grep uid | head -n 1)
    RECIPIENT=$(echo "$uid" | grep -E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b")

    fingerprint=$(gpg -K "${RECIPIENT}" | grep fingerprint | head -n 1 | cut -d= -f2 | sed 's/ //g')
    _verbose "Primary key fingerprint: $fingerprint"

    # GPG & Coffin Backup
    if [[ ! -d $MOUNT_POINT ]]; then
            _verbose "Creating mount point directory"
            mkdir $MOUNT_POINT &> /dev/null
            _verbose "Changing directory owner to $USER"
            sudo chown "$USER" $MOUNT_POINT
    fi

    _verbose "Opening LUKS pendrive"
    sudo cryptsetup open --type luks "$PENDRIVE" $MAPPER
    _catch "Failed to open LUKS pendrive. Aborting"
    sudo mount /dev/mapper/${MAPPER} $MOUNT_POINT

    BCKDIR="${MOUNT_POINT}/gpg/${IDENTITY}"
    if [[ ! -d $BCKDIR ]]; then
            _verbose "Creating backup directory for $IDENTITY"
            mkdir -p "$BCKDIR"
    fi

    # GPG backup
    _verbose "Opening identity $IDENTITY"
    _verbose "Backing up gpg -K output on drive (as gpg-k_output.txt)"
    gpg -K > "${BCKDIR}"/gpg-k_output.txt
    gpg_base_cmd=(gpg --pinentry-mode loopback --batch --no-tty --yes --passphrase-fd 0)

    # Primary key-pair backup
    _verbose "Backing up primary key-pair (armored)"
    _verbose "Private key"
    echo "$GPG_PASS" | "${gpg_base_cmd[@]}" --export-secret-keys \
        --armor "$fingerprint" > "${BCKDIR}"/private-primary-keypair.arm.key
    _verbose "Public key"
    gpg --export --armor "$fingerprint" > "${BCKDIR}"/public-primary-keypair.arm.key

    # Subkey-pairs backup
    _verbose "Backing up subkey-pairs (armored)"
    echo "$GPG_PASS" | "${gpg_base_cmd[@]}" --export-secret-subkeys \
        "$fingerprint" > "${BCKDIR}"/private-subkeys.bin.key
    _verbose "Listing directory (should have 4 files for this identity)"
    _verbose "$(ls -l "$BCKDIR")"

    # Graveyard backup 
    _verbose "Backing tomb files"
    _verbose "Backing up graveyard to pendrive"
    if [[ ! -d ${MOUNT_POINT}/graveyard ]]; then
            _verbose "Creating graveyard directory on pendrive"
            mkdir ${MOUNT_POINT}/graveyard &> /dev/null
    fi

    _verbose "Copying graveyard files"
    _run sudo chattr -i ${MOUNT_POINT}/graveyard/* \
        || _verbose "No files in backup/graveyard for which to change immutability properties"
    IDENTITY_GRAVEYARD_PATH=$(get_identity_graveyard "$IDENTITY")
    _run cp -fR "${IDENTITY_GRAVEYARD_PATH}"/* ${MOUNT_POINT}/graveyard
    _catch "Failed to copy graveyard files to backup medium"

    # Unmount and close everything before backing the hush image 
    _verbose "Closing identity $IDENTITY"
    close_coffin "$IDENTITY"

    # Hush image backup
    _message "Backing hush partition"
    _verbose "Unmounting hush partition"
    _run risks_hush_umount_command
    if [[ -e ${MOUNT_POINT}/hush.img ]]; then
            sudo chattr -i ${MOUNT_POINT}/hush.img          # Otherwise we can't overwrite
    fi
    sudo dd if=/dev/hush of=${MOUNT_POINT}/hush.img status=progress bs=16M

    # Testing the full backup 
    _verbose "Testing backup"
    _verbose "Printing directory tree in backup pendrive"
    _verbose "$(tree $MOUNT_POINT)"
    _verbose "Should have 4 files in gpg/${IDENTITY}/, hush.img and graveyard in root"
    _verbose "Making all backup files immutable"
    sudo chattr +i ${MOUNT_POINT}/graveyard/*
    sudo chattr +i ${MOUNT_POINT}/hush.img
    sudo chattr +i ${MOUNT_POINT}/gpg/"${IDENTITY}"/*

    _verbose "Unmounting backup pendrive"
    sudo umount $MOUNT_POINT
    _verbose "Closing LUKS filesystem"
    sudo cryptsetup close $MAPPER
    rm -rf "$MOUNT_POINT"
}
