
# Ensure a backup is mounted
if ! is_luks_mapper_present "$BACKUP_MAPPER" ; then
    _failure "No mounted backup medium found. Mount one with risks backup mount </dev/device>"
fi

local BACKUP_GRAVEYARD_ROOT="${BACKUP_MOUNT_DIR}/graveyard"

local IDENTITY_GRAVEYARD_PATH IDENTITY_BACKUP_GRAVEYARD_PATH GRAVEYARD_DIRECTORY_ENC

GRAVEYARD_DIRECTORY_ENC=$(_encrypt_filename "$IDENTITY")
IDENTITY_GRAVEYARD_PATH="${GRAVEYARD}/${GRAVEYARD_DIRECTORY_ENC}"
IDENTITY_BACKUP_GRAVEYARD_PATH="${BACKUP_GRAVEYARD_ROOT}/${GRAVEYARD_DIRECTORY_ENC}"

## First make sure the backup directory for the identity is unlocked
echo "$FILE_ENCRYPTION_KEY" | _run sudo fscrypt unlock "$IDENTITY_BACKUP_GRAVEYARD_PATH" --quiet

# Backup the GPG coffin for this identity
_verbose "Backing GPG" 
_run backup_identity_gpg "${BACKUP_MOUNT_DIR}/graveyard" 

# Graveyard backup for this identity.
_verbose "Backing graveyard files"
_run sudo chattr -i "${IDENTITY_BACKUP_GRAVEYARD_PATH}"/* \
    || _verbose "No files in backup/graveyard for which to change immutability properties"
_run cp -fR "${IDENTITY_GRAVEYARD_PATH}"/* "${IDENTITY_BACKUP_GRAVEYARD_PATH}"
_catch "Failed to copy graveyard files to backup medium"
_verbose "Making graveyard backup files immutable"

# We don't need the identity backup graveyard anymore, lock it
_run sudo fscrypt lock "${IDENTITY_BACKUP_GRAVEYARD_PATH}"

# And backup hush, since it has new content
risks_backup_hush_command

# Testing the full backup 
_verbose "Printing directory tree in backup pendrive"
_verbose "$(tree "$BACKUP_MOUNT_DIR")"

_message "Done backing current identity and hush device"

