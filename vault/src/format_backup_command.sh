# Easily cleanup, format, luks-encrypt and filesystem setup for a USB drive
# to be used as a backup medium for risks data.

PENDRIVE="${args[device]}"
MAPPER="pendev"
MOUNT_POINT="/tmp/pendrive"

# Data cleanup
_message "backup" "Formatting and encrypting backup drive"
_verbose "backup" "Overwriting drive data"
sudo dd if=/dev/urandom of="${PENDRIVE}" bs=1M status=progress && sync

# Encryption setup
_message "backup" "Setting up LUKS on drive"
_run "backup" sudo cryptsetup -v -q -y --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat "${PENDRIVE}"
_catch "backup" "Failed to setup LUKS filesystem on backup drive"

# Filesystem setup
mkdir ${MOUNT_POINT} &> /dev/null
_run "backup" sudo cryptsetup open --type luks "${PENDRIVE}" ${MAPPER} 
_catch "backup" "Failed to open backup LUKS filesystem"
_message "backup" "Making ext4 filesystem on LUKS mapper"
_run "backup" sudo mkfs.ext4 -m 0 -L "gpg-backup" /dev/mapper/${MAPPER} 
_catch "backup" "Failed to make ext4 filesystem on backup"
_run "backup" sudo /sbin/tune2fs -O encrypt "/dev/mapper/${MAPPER}" 
_catch "backup" "Failed to enable encryption on ext4 filesystem"

# fsencrypt setup
_run "backup" sudo mount /dev/mapper/${MAPPER} ${MOUNT_POINT} 
_catch "backup" "Failed to mount partition on ${MOUNT_POINT}"
sudo chown "${USER}" ${MOUNT_POINT} 
_message "backup" "Setting up fscrypt in backup mount point (${MOUNT_POINT})"
echo "N" | sudo fscrypt setup "${MOUNT_POINT}" 
_catch "backup" "Failed to setup fscrypt metadata with root permissions"

# Closing
_verbose "backup" "Unmounting backup pendrive"
_run "backup" sudo umount ${MOUNT_POINT} 
_catch "backup" "Failed to unmount ${MOUNT_POINT}"
_verbose "backup" "Closing LUKS filesystem" 
_run "backup" sudo cryptsetup close ${MAPPER} 
_catch "backup" "Failed to close LUKS filesystem on ${MAPPER}" 
