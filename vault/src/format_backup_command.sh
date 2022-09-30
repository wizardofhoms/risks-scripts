# Easily cleanup, format, luks-encrypt and filesystem setup for a USB drive
# to be used as a backup medium for risks data.

PENDRIVE="${args[device]}"
MAPPER="pendev"
MOUNT_POINT="/tmp/pendrive"

_message "Formatting and encrypting backup drive"

# Data cleanup
_verbose "Overwriting drive data"
sudo dd if=/dev/urandom of="${PENDRIVE}" bs=1M status=progress && sync

# Encryption setup
_message "Setting up LUKS on drive"
sudo cryptsetup -v -q -y --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat "${PENDRIVE}"
_catch "Failed to setup LUKS filesystem on backup drive"

# Filesystem setup
mkdir ${MOUNT_POINT} &> /dev/null
sudo cryptsetup open --type luks "${PENDRIVE}" ${MAPPER} 
_catch "Failed to open backup LUKS filesystem"
_message "Making ext4 filesystem on LUKS mapper"
_run sudo mkfs.ext4 -m 0 -L "gpg-backup" /dev/mapper/${MAPPER} 
_catch "Failed to make ext4 filesystem on backup"
_run sudo /sbin/tune2fs -O encrypt "/dev/mapper/${MAPPER}" 
_catch "Failed to enable encryption on ext4 filesystem"

# fsencrypt setup
_run sudo mount /dev/mapper/${MAPPER} ${MOUNT_POINT} 
_catch "Failed to mount partition on ${MOUNT_POINT}"
sudo chown "${USER}" ${MOUNT_POINT} 
_message "Setting up fscrypt in backup mount point (${MOUNT_POINT})"
echo "N" | sudo fscrypt setup "${MOUNT_POINT}" &> /dev/null
_catch "Failed to setup fscrypt metadata with root permissions"

# Closing
_message "Unmounting backup pendrive"
_run sudo umount ${MOUNT_POINT} 
_catch "Failed to unmount ${MOUNT_POINT}"
_message 
_run sudo cryptsetup close ${MAPPER} 
_catch 

_success "Done formatting and encrypting backup drive"
