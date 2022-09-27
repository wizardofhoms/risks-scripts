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
sudo cryptsetup -v -q -y --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat "${PENDRIVE}" \
        || _failure "backup" "Failed to setup LUKS filesystem on backup drive"

# Filesystem setup
mkdir ${MOUNT_POINT} &> /dev/null
sudo cryptsetup open --type luks "${PENDRIVE}" ${MAPPER} || _failure "pendrive" "Failed to open backup LUKS filesystem"
_message "backup" "Making ext4 filesystem on LUKS mapper"
sudo mkfs.ext4 -m 0 -L "gpg-backup" /dev/mapper/${MAPPER} || _failure "hush" "Failed to make ext4 filesystem on backup"
sudo /sbin/tune2fs -O encrypt "/dev/mapper/${MAPPER}" || _failure "backup" "Failed to enable encryption on ext4 filesystem"

# fsencrypt setup
sudo mount /dev/mapper/${MAPPER} ${MOUNT_POINT} || _failure "hush" "Failed to mount partition on ${MOUNT_POINT}"
sudo chown "${USER}" ${MOUNT_POINT} 
_verbose "backup" "Setting up fscrypt in backup mount point (${MOUNT_POINT})"
echo "N" | sudo fscrypt setup "${MOUNT_POINT}" || _failure "backup" "Failed to setup fscrypt metadata with root permissions"

# Closing
_verbose "backup" "Unmounting backup pendrive"
sudo umount ${MOUNT_POINT} || _failure "Failed to unmount ${MOUNT_POINT}"
_verbose "backup" "Closing LUKS filesystem" 
sudo cryptsetup close ${MAPPER} || _failure "hush" "Failed to close LUKS filesystem on ${MAPPER}" 
