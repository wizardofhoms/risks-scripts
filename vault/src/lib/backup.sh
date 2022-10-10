
# The identity needs its own backup directory.
setup_identity_backup () 
{
    local backup_graveyard          # Where the graveyard root directory is in the backup drive
    local identity_graveyard        # The full path to the identity system graveyard.
    local identity_dir              # The encrypted graveyard directory for the identity
    local identity_graveyard_backup # Full path to identity graveyard backup

    backup_graveyard="${BACKUP_MOUNT_DIR}/graveyard"

    _verbose "Creating identity graveyard directory on backup"

    # The directory name in cleartext is simply the identity name
    identity_dir=$(_encrypt_filename "$IDENTITY")
    identity_graveyard_backup="${backup_graveyard}/${identity_dir}"

    _verbose "Creating directory $identity_graveyard"
    mkdir -p "$identity_graveyard_backup"

    # And setup fscrypt protectors on it.
    _verbose "Setting up fscrypt protectors on directory"
    echo "$FILE_ENCRYPTION_KEY" | sudo fscrypt encrypt "$identity_graveyard_backup" \
       --quiet --source=custom_passphrase --name="$identity_dir"
    _catch "Failed to encrypt identity graveyard in backup"
}

# backup_identity_gpg simply copies the raw coffin file in the graveyard backup directory root,
# since like on the system graveyard, one must access it without having access to the graveyard in
# the first place.
backup_identity_gpg () 
{
    local backup_graveyard          # Where the graveyard root directory is in the backup drive
    local identity_dir              # The encrypted graveyard directory for the identity
    local coffin_file               # Encrypted name of the coffin file
    local coffin_path               # Full path to the identity coffin in the system graveyard
    local coffin_backup_path        # Full path to the same coffin, in the backup graveyard

    backup_graveyard="${BACKUP_MOUNT_DIR}/graveyard"

    # The directory name in cleartext is simply the identity name
    coffin_file=$(_encrypt_filename "coffin-$IDENTITY-gpg")
    coffin_path="${GRAVEYARD}/${coffin_file}"

    identity_dir=$(_encrypt_filename "$IDENTITY")
    coffin_backup_path="${backup_graveyard}/${identity_dir}/${coffin_file}"

    if [[ -e ${coffin_path} ]]; then
        sudo chattr -i "${coffin_path}" 
    fi

    cp -r "$coffin_path" "$coffin_backup_path"
    sudo chattr +i "${coffin_path}" 
}
