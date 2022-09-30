# Easily cleanup, format, luks-encrypt and filesystem setup onto an SDCard
# to be used as a store for the various identities' data (excluding backup).
# $1 - The device file to the SDCard (raw device, not partition, eg. /dev/sda, not /dev/sda1)
# $2 - The size for the encrypted partition, either absolute or relative, to pass to the fdisk command.

sd_drive="${args[device]}"        # Device file 
sd_ext4_drive="$sd_drive"1        # Dumb partition
sd_enc_part="$sd_drive"2          # Encrypted partition
mount_point="${HUSH_DIR}"

# Sizes: by default 90% of the drive is used as encrypted partition,
# but flag --percent-size or --absolute-size can modify size.
# If absolute size was specified, use it and forget all other values
if [[ -n "${args[--size-absolute]}" ]]; then
    enc_part_size="${args[--size-absolute]}"
    start_enc_sectors="${enc_part_size}"
else
    percent_size="${args[--size-percent]}"  
    total_size="$(sudo blockdev --getsize "${sd_drive}")"
    enc_part_size="$(( total_size * percent_size / 100 ))"
    start_enc_sectors="$(( total_size - enc_part_size - 2048 ))"
fi

# Cleanup & making partitions 
_message "Overwriting and partitioning SDCARD"
_verbose "Cleaning drive"
 sudo dd if=/dev/urandom of="${sd_drive}" bs=1M status=progress && sync 
_message "Creating partitions"

nl=$'\n' # Needed because EOF does not preserve some newlines.
_run sudo fdisk -u "${sd_drive}" <<-EOF
n
p
1

+${start_enc_sectors}
n
p
2

$nl
w

EOF
_catch "Failed to format partitions"

# Automounting the first partition on any OS
_verbose "Making 1st partition mountable by default for all OS (fat32)"
_run sudo mkfs.vfat -F 32 -n DATA "${sd_ext4_drive}" 
_catch "Failed to make vfat32 filesystem"

# Hush partition encryption setup 
mkdir "${mount_point}" &> /dev/null
_message "Creating LUKS filesystem"
sudo cryptsetup -v -q -y --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat "$sd_enc_part"
_catch "Failed to format drive with LUKS"

_verbose "Checking LUKS partition status"
sudo cryptsetup open --type luks "${sd_enc_part}" "${SDCARD_ENC_PART_MAPPER}" 
_catch "Failed to open LUKS drive"
_verbose "$(sudo cryptsetup status "${SDCARD_ENC_PART_MAPPER}")"

# Ext4 with encryption support (for fscrypt) and fscrypt setup
_message "Making filesytem and setting up high-level encryption (fscrypt)"
_run sudo mkfs.ext4 -m 0 -L "hush" "/dev/mapper/${SDCARD_ENC_PART_MAPPER}" 
_catch "Failed to make ext4 filesystem on partition"
_run sudo /sbin/tune2fs -O encrypt "/dev/mapper/${SDCARD_ENC_PART_MAPPER}" 
_catch "Failed to enable encryption on ext4 filesystem"
_run sudo mount -o rw "/dev/mapper/${SDCARD_ENC_PART_MAPPER}" "${mount_point}" 
_catch "Failed to mount partition on ${mount_point}"       
sudo chown "${USER}" "${HUSH_DIR}"
_verbose "Setting up fscrypt in hush mount point (${mount_point})"
sudo fscrypt setup --quiet --force "${mount_point}"
_catch "Failed to setup fscrypt metadata with root permissions"

# Checks
_verbose "$(mount | grep "${SDCARD_ENC_PART_MAPPER}")"
_verbose "Last command should give the following result:                     \n \
    /dev/mapper/hush on /home/user/.hush type ext4 (rw,relatime,data=ordered)       \n \
    /dev/mapper/hush on /rw/home/user/.hush type ext4 (rw,relatime,data=ordered)    \n\n"

# Write our risks scripts in a special directory on the hush, and close the device.
store_risks_scripts

# Note that even if we fail to umount at $mount_point, we still try to cryptsetup close hush.
_verbose "Closing and unmounting device"
_run sudo umount "${mount_point}" 
_catch "Failed to unmount ${mount_point}"                   
_run sudo cryptsetup close "${SDCARD_ENC_PART_MAPPER}" 
_catch "Failed to close LUKS filesystem on ${SDCARD_ENC_PART_MAPPER}" 

# Setup udev identitiers mapping for hush partition 
_message "Setting Udev rules for hush partition " 
UUID=$(sudo cryptsetup luksUUID "${sd_enc_part}")
sudo sh -c 'echo SUBSYSTEM==\"block\", ENV{ID_FS_UUID}==\"'"${UUID}"'\", SYMLINK+=\"hush\" > /etc/udev/rules.d/99-sdcard.rules'
_catch "Failed to write udev mapper file with SDCard UUID"
_verbose "Restarting udev service" 
sudo udevadm control --reload-rules
_success "Successfully formatted and prepared SDcard as hush device"

