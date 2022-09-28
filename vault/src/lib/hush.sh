# Checks if the "hush partition" has been seen by kernel and returns 0 if true
is_partition_mapper_present()
{
    ls -1 "/dev/${SDCARD_ENC_PART_MAPPER}" &> /dev/null
}

# Checks if the "hush partition" has been already decrypted and returns 0 if true
is_luks_mapper_present()
{
    ls -1 "/dev/mapper/${SDCARD_ENC_PART_MAPPER}" &> /dev/null
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
