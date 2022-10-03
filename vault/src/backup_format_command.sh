# Easily cleanup, format, luks-encrypt and filesystem setup for a USB drive
# to be used as a backup medium for risks data.

PENDRIVE="${args[device]}"

_message "Formatting and encrypting backup drive"

# Data cleanup
_verbose "Overwriting drive data"
sudo dd if=/dev/urandom of="${PENDRIVE}" bs=1M status=progress && sync

# Encryption setup
_message "Setting up LUKS on drive"
sudo cryptsetup -v -q -y --cipher aes-xts-plain64 --key-size 512 \
    --hash sha512 --iter-time 5000 --use-random luksFormat "${PENDRIVE}"
_catch "Failed to setup LUKS filesystem on backup drive"

# Filesystem setup
mkdir "${BACKUP_MOUNT_DIR}" &> /dev/null
sudo cryptsetup open --type luks "${PENDRIVE}" "${BACKUP_MAPPER}" 
_catch "Failed to open backup LUKS filesystem"

_message "Making ext4 filesystem on LUKS mapper"
_run sudo mkfs.ext4 -m 0 -L "backup" /dev/mapper/"${BACKUP_MAPPER}" 
_catch "Failed to make ext4 filesystem on backup"

# fsencrypt setup
_message "Enabling filesystem encryption and setting up fscrypt"
_run sudo /sbin/tune2fs -O encrypt "/dev/mapper/${BACKUP_MAPPER}" 
_catch "Failed to enable encryption on ext4 filesystem"

_run sudo mount /dev/mapper/"${BACKUP_MAPPER}" "${BACKUP_MOUNT_DIR}" 
_catch "Failed to mount partition on ${BACKUP_MOUNT_DIR}"
sudo chown "${USER}" "${BACKUP_MOUNT_DIR}" 
_message "Setting up fscrypt in backup mount point (${BACKUP_MOUNT_DIR})"
echo "N" | sudo fscrypt setup "${BACKUP_MOUNT_DIR}" &> /dev/null
_catch "Failed to setup fscrypt metadata with root permissions"

# Closing
_message "Unmounting backup pendrive"
risks_backup_umount_command
_catch "Failed to correctly unmount backup device"

_success "Done formatting and encrypting backup drive"
_success "Use 'risks backup mount' to get read-write access"
