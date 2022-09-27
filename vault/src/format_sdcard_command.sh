# Easily cleanup, format, luks-encrypt and filesystem setup onto an SDCard
# to be used as a store for the various identities' data (excluding backup).
# $1 - The device file to the SDCard (raw device, not partition, eg. /dev/sda, not /dev/sda1)
# $2 - The size for the encrypted partition, either absolute or relative, to pass to the fdisk command.

sd_drive="${args[device]}"        # Device file 
enc_part_size="${args[size]}"     # Size of encrypted partition
sd_ext4_drive="$sd_drive"1        # Dumb partition
sd_enc_part="$sd_drive"2          # Encrypted partition
mount_point="${HUSH_DIR}"

# 1 - Cleanup & partitions 
_message "fs" "Overwriting and partitioning SDCARD"
_verbose "fs" "Cleaning drive"
sudo dd if=/dev/urandom of="${sd_drive}" bs=1M status=progress && sync 
_verbose "fs" "Creating partitions"
sudo fdisk -u "${sd_drive}" <<-EOF
n
p
1

+${enc_part_size}
n
p
2


w
EOF

if ! $? ; then _failure "fs" "Failed to format partitions"; fi

# Automounting the first partition on any OS
_verbose "fs" "Making 1st partition mountable by default for all OS (fat32)"
sudo mkfs.vfat -F 32 -n DATA "${sd_ext4_drive}" || _failure "fs" "Failed to make vfat32 filesystem"

# Hush partition encryption setup 
_message "hush" "Hush partition setup" 
mkdir "${mount_point}" &> /dev/null
_verbose "hush" "Creating LUKS filesystem"
sudo cryptsetup -v -q -y --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat "$sd_enc_part" \
        || _failure "hush" "Failed to format drive with LUKS"

_verbose "hush" "Checking LUKS partition status"
sudo cryptsetup open --type luks "${sd_enc_part}" "${SDCARD_ENC_PART_MAPPER}" || _failure "hush" "Failed to open LUKS drive"
_verbose "$(sudo cryptsetup status "${SDCARD_ENC_PART_MAPPER}")"

# Ext4 with encryption support (for fscrypt) and fscrypt setup
_verbose "hush" "Formatting and mounting device on root filesystem"
sudo mkfs.ext4 -m 0 -L "hush" "/dev/mapper/${SDCARD_ENC_PART_MAPPER}" || _failure "hush" "Failed to make ext4 filesystem on partition"
sudo /sbin/tune2fs -O encrypt "/dev/mapper/${SDCARD_ENC_PART_MAPPER}" || _failure "hush" "Failed to enable encryption on ext4 filesystem"
sudo mount "/dev/mapper/${SDCARD_ENC_PART_MAPPER}" "${mount_point}" || _failure "hush" "Failed to mount partition on ${mount_point}"       
_verbose "hush" "Setting up fscrypt in hush mount point (${mount_point})"
echo "N" | sudo fscrypt setup "${mount_point}" || _failure "hush" "Failed to setup fscrypt metadata with root permissions"

# Checks
_verbose "$(mount | grep "${SDCARD_ENC_PART_MAPPER}")"
_verbose "hush" "Last command should give the following result:                     \n \
    /dev/mapper/hush on /home/user/.hush type ext4 (rw,relatime,data=ordered)       \n \
    /dev/mapper/hush on /rw/home/user/.hush type ext4 (rw,relatime,data=ordered)    \n\n"

# Write our risks scripts in a special directory on the hush, and close the device.
# Note that even if we fail to umount at $mount_point, we still try to cryptsetup close hush.
store_risks_scripts
_verbose "hush" "Closing and unmounting device"
sudo umount "${mount_point}" || _warning "hush" "Failed to unmount ${mount_point}"                   
sudo cryptsetup close "${SDCARD_ENC_PART_MAPPER}" || _failure "hush" "Failed to close LUKS filesystem on ${SDCARD_ENC_PART_MAPPER}" 

# Setup udev identitiers mapping for hush partition 
_message "udev" "Setting Udev rules for hush partition " 
UUID=$(sudo cryptsetup luksUUID "${sd_enc_part}")
sudo sh -c 'echo SUBSYSTEM==\"block\", ENV{ID_FS_UUID}==\"'${UUID}'\", SYMLINK+=\"hush\" > /etc/udev/rules.d/99-sdcard.rules' \
        || _failure "hush" "Failed to write udev mapper file with SDCard UUID"
_verbose "udev" "Restarting udev service" 
sudo udevadm control --reload-rules

