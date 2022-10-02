
PENDRIVE="${args[device]}" 
MAPPER="pendev"
MOUNT_POINT="/tmp/pendrive"

_message "Making new backup for current identity and hush device image"

# Mount and decrypt the backup drive, or fail
_verbose "Opening backup LUKS filesystem"
sudo cryptsetup open --type luks "$PENDRIVE" $MAPPER 
_catch "Failed to open backup LUKS filesystem"
sudo mount /dev/mapper/$MAPPER $MOUNT_POINT \
    || sudo cryptsetup close $MAPPER && _failure "Failed to mount LUKS filesystem"

# Hush backup
_message "Backing hush partition"
_verbose "Unmounting hush partition"
hush_umount_command
_verbose "Backing up hush as .img to pendrive"
if [[ -e ${MOUNT_POINT}/hush.img ]]; then
        sudo chattr -i $MOUNT_POINT/hush.img          # Otherwise we can't overwrite
fi
sudo dd if=/dev/hush of=$MOUNT_POINT/hush.img status=progress bs=16M

# Graveyard backup 
_message "Backing tomb files"
_verbose "Backing up graveyard to pendrive"
if [[ ! -d $MOUNT_POINT/graveyard ]]; then
        _verbose "Creating graveyard directory on pendrive"
        mkdir $MOUNT_POINT/graveyard &> /dev/null
fi
_verbose "Copying graveyard files"
sudo chattr -i $MOUNT_POINT/graveyard/* \
    || _verbose "No files in backup/graveyard for which to change immutability properties"
cp -fR "${HOME}"/.graveyard/* $MOUNT_POINT/graveyard 
_catch "Failed to copy graveyard files to backup medium"

# And finally unmount everything.
_verbose "Unmounting backup pendrive"
sudo umount $MOUNT_POINT
_verbose "Closing LUKS filesystem"
sudo cryptsetup close $MAPPER

_success "Done backing up identity data and hush image"
