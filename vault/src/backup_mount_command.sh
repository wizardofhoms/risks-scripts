
pendrive="${args[backup_device]}"

# If we already have a device mounted as backup, fail.
if ls -1 /dev/mapper/"${BACKUP_MAPPER}" &> /dev/null; then
    _message "Backup device is already mounted"
    play_sound
    return 0
fi


if [[ ! -d $BACKUP_MOUNT_DIR ]]; then
    _verbose "Creating mount point directory $BACKUP_MOUNT_DIR"
    mkdir "$BACKUP_MOUNT_DIR" &> /dev/null
    _verbose "Changing directory owner to $USER"
    sudo chown "$USER" "$BACKUP_MOUNT_DIR"
fi

_verbose "Opening LUKS pendrive"
sudo cryptsetup open --type luks "$pendrive" "$BACKUP_MAPPER"
_catch "Failed to open LUKS pendrive. Aborting"
sudo mount /dev/mapper/"${BACKUP_MAPPER}" "$BACKUP_MOUNT_DIR"

_message "Backup unlocked and mounted on ${BACKUP_MOUNT_DIR}"
