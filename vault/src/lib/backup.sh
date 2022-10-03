
# The identity needs its own backup directory.
setup_identity_backup () 
{
    local BACKUP_GRAVEYARD_ROOT="${BACKUP_MOUNT_DIR}/graveyard"

    local GRAVEYARD_DIRECTORY_ENC IDENTITY_GRAVEYARD_PATH

    _verbose "Creating identity graveyard directory on backup"

    # The directory name in cleartext is simply the identity name
    GRAVEYARD_DIRECTORY_ENC=$(_encrypt_filename "$IDENTITY")
    IDENTITY_BACKUP_GRAVEYARD_PATH="${BACKUP_GRAVEYARD_ROOT}/${GRAVEYARD_DIRECTORY_ENC}"

    _verbose "Creating directory $IDENTITY_GRAVEYARD_PATH"
    mkdir -p "$IDENTITY_BACKUP_GRAVEYARD_PATH"

    # And setup fscrypt protectors on it.
    _verbose "Setting up fscrypt protectors on directory"
    echo "$FILE_ENCRYPTION_KEY" | sudo fscrypt encrypt "$IDENTITY_BACKUP_GRAVEYARD_PATH" \
       --quiet --source=custom_passphrase --name="$GRAVEYARD_DIRECTORY_ENC"
    _catch "Failed to encrypt identity graveyard in backup"
}

# backup_identity_gpg simply copies the raw coffin file in the graveyard backup directory root,
# since like on the OS graveyard, one must access it without having access to the graveyard in
# the first place.
backup_identity_gpg () 
{
    local BACKUP_GRAVEYARD_ROOT="${BACKUP_MOUNT_DIR}/graveyard"

    local GRAVEYARD_COFFIN_FILE IDENTITY_COFFIN_PATH COFFIN_BACKUP_PATH 

    # The directory name in cleartext is simply the identity name
    GRAVEYARD_COFFIN_FILE=$(_encrypt_filename "coffin-$IDENTITY-gpg")
    IDENTITY_COFFIN_PATH="${GRAVEYARD}/${GRAVEYARD_COFFIN_FILE}"

    GRAVEYARD_DIRECTORY_ENC=$(_encrypt_filename "$IDENTITY")
    COFFIN_BACKUP_PATH="${BACKUP_GRAVEYARD_ROOT}/${GRAVEYARD_DIRECTORY_ENC}/${GRAVEYARD_COFFIN_FILE}"

    if [[ -e ${IDENTITY_COFFIN_PATH} ]]; then
        sudo chattr -i "${IDENTITY_COFFIN_PATH}" 
    fi

    cp -r "$IDENTITY_COFFIN_PATH" "$COFFIN_BACKUP_PATH"
    sudo chattr +i "${IDENTITY_COFFIN_PATH}" 
}
