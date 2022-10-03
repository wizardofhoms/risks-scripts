
# if backup is not found, fail and ask to mount
if ! is_luks_mapper_present "$BACKUP_MAPPER" ; then
    _failure 'Backup device not mounted. Please mount with `risks backup mount DEVICE`'
fi

_message "Backing hush partition"

_verbose "Unmounting hush partition"
risks_hush_umount_command

if [[ -e ${BACKUP_MOUNT_DIR}/hush.img ]]; then
    sudo chattr -i "${BACKUP_MOUNT_DIR}"/hush.img
fi
sudo dd if=/dev/hush of="${BACKUP_MOUNT_DIR}/hush.img" status=progress bs=16M
sudo chattr +i "${BACKUP_MOUNT_DIR}/hush.img" || _warning "No hush.img file found after dd operation"

_message "Done backing hush partition"
