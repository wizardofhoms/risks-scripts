# Checks if the "hush partition" has been seen by kernel and returns 0 if true
is_named_partition_mapper_present()
{
    ls -1 "/dev/${1}" &> /dev/null
}

# Checks if the "hush partition" has been already decrypted and returns 0 if true
is_luks_mapper_present()
{
    ls -1 "/dev/mapper/${1}" &> /dev/null
}

# Checks if the "hush partition" is already mounted and returns 0 if true
is_hush_mounted()
{
	mount | grep "^/dev/mapper/${SDCARD_ENC_PART_MAPPER}" &> /dev/null
}

is_luks_open()
{
    ls "/dev/mapper/${1}" &> /dev/null
}

is_luks_mounted()
{
	mount | grep "^${1}" &> /dev/null
}

# Check if a *block* device is encrypted
# Synopsis: _is_encrypted_block /path/to/block/device
# Return 0 if it is an encrypted block device
is_encrypted_block() {
	local	 b=$1 # Path to a block device
	local	 s="" # lsblk option -s (if available)

	# Issue #163
	# lsblk --inverse appeared in util-linux 2.22
	# but --version is not consistent...
	lsblk --help | grep -Fq -- --inverse
	[[ $? -eq 0 ]] && s="--inverse"

    sudo lsblk $s -o type -n "$b" 2>/dev/null \
		| grep -e -q '^crypt$'
		# | egrep -q '^crypt$'

	return $?
}

