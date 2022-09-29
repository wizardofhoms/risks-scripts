
PENDRIVE="${args[device]}" 
MAPPER="pendev"
MOUNT_POINT="/tmp/pendrive"

# Mount and decrypt the backup drive, or fail
_verbose "backup" "Opening backup LUKS filesystem"
sudo cryptsetup open --type luks "${PENDRIVE}" ${MAPPER} 
_catch "backup" "Failed to open backup LUKS filesystem"
sudo mount /dev/mapper/${MAPPER} ${MOUNT_POINT} \
    || sudo cryptsetup close ${MAPPER} && _failure "backup" "Failed to mount LUKS filesystem"

# Hush backup
_message "backup" "Backing hush partition"
_verbose "backup" "Unmounting hush partition"
hush_umount_command
_verbose "backup" "Backing up hush as .img to pendrive"
if [[ -e ${MOUNT_POINT}/hush.img ]]; then
        sudo chattr -i ${MOUNT_POINT}/hush.img          # Otherwise we can't overwrite
fi
sudo dd if=/dev/hush of=${MOUNT_POINT}/hush.img status=progress bs=16M

# Graveyard backup 
_message "backup" "Backing tomb files"
_verbose "backup (graveyard)" "Backing up graveyard to pendrive"
if [[ ! -d ${MOUNT_POINT}/graveyard ]]; then
        _verbose "backup (graveyard)" "Creating graveyard directory on pendrive"
        mkdir ${MOUNT_POINT}/graveyard &> /dev/null
fi
_verbose "backup (graveyard)" "Copying graveyard files"
sudo chattr -i ${MOUNT_POINT}/graveyard/* \
    || _verbose "backup" "No files in backup/graveyard for which to change immutability properties"
cp -fR "${HOME}"/.graveyard/* ${MOUNT_POINT}/graveyard 
_catch "backup" "Failed to copy graveyard files to backup medium"

# And finally unmount everything.
_verbose "backup" "Unmounting backup pendrive"
sudo umount ${MOUNT_POINT}
_verbose "backup" "Closing LUKS filesystem"
sudo cryptsetup close ${MAPPER}
