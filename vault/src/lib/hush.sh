
# Checks if the "hush partition" has been seen by kernel and returns 0 if true
is_partition_mapper_present()
{
	ls -1 /dev/${SDCARD_ENC_PART_MAPPER} &> /dev/null
}

# Checks if the "hush partition" has been already decrypted and returns 0 if true
is_luks_mapper_present()
{
	ls -1 /dev/mapper/${SDCARD_ENC_PART_MAPPER} &> /dev/null
}

# Checks if the "hush partition" is already mounted and returns 0 if true
is_hush_mounted()
{
	mount | grep "^/dev/mapper/${SDCARD_ENC_PART_MAPPER}" &> /dev/null
}

mount_hush()
{
	global_var_check "SDCARD_ENC_PART"
	global_var_check "SDCARD_ENC_PART_MAPPER"
	global_var_check "HUSH_DIR"
	global_var_check "SDCARD_QUIET"

	if ! is_partition_mapper_present ; then
		_failure "hush" "Device mapper /dev/${SDCARD_ENC_PART_MAPPER} not found."
		_failure "hush" "Be sure you have attached your hush partition."
		exit 1
	fi

	if is_hush_mounted ; then
		_message "hush" "Sdcard already mounted"
		play_sound
		exit 0
	fi

	if ! is_luks_mapper_present ; then
		# decrypts the "hush partition": it will ask for passphrase
		if ! sudo cryptsetup open --type luks ${SDCARD_ENC_PART} ${SDCARD_ENC_PART_MAPPER} ; then
			_failure "hush" "The hush partition ${SDCARD_ENC_PART} can not be decrypted"
			exit 1
		fi
	fi

	# creates the "hush partition" mount point if it doesn't exist
	if [ ! -d ${HUSH_DIR} ]; then
	    mkdir -p ${HUSH_DIR} &> /dev/null
	fi

	# mounts the "hush partition" in read-only mode by default
	if ! sudo mount -o ro /dev/mapper/${SDCARD_ENC_PART_MAPPER} ${HUSH_DIR} ; then
		_failure "hush" "/dev/mapper/${SDCARD_ENC_PART_MAPPER} can not be mounted on ${HUSH_DIR}"
		exit 1
	fi


	play_sound "plugged"
}

umount_hush()
{
	global_var_check "SDCARD_ENC_PART"
	global_var_check "SDCARD_ENC_PART_MAPPER"
	global_var_check "HUSH_DIR"
	global_var_check "SDCARD_QUIET"

	if ! is_partition_mapper_present ; then
		_failure "risks" "Device mapper /dev/mapper/${SDCARD_ENC_PART_MAPPER} not found.\n \
		Be sure you have attached your hush partition."
	fi

	if is_hush_mounted ; then
		if ! sudo umount -f ${HUSH_DIR} ; then
			_failure "risks" "/dev/mapper/${SDCARD_ENC_PART_MAPPER} can not be umounted from ${HUSH_DIR}"
		fi
	fi

	if is_luks_mapper_present ; then
		if ! sudo cryptsetup close ${SDCARD_ENC_PART_MAPPER} ; then
			_failure "risks" "SDCARD can not be closed"
		fi
	fi

	play_sound "unplugged"
}

ro_hush()
{
	global_var_check "SDCARD_ENC_PART"
	global_var_check "SDCARD_ENC_PART_MAPPER"
	global_var_check "HUSH_DIR"

	if ! is_hush_mounted ; then
		_failure "risks" "HUSH is not mounted"
	fi

	mount_option="remount,ro"
	if ! sudo mount -o ${mount_option} /dev/mapper/${SDCARD_ENC_PART_MAPPER} ${HUSH_DIR} &> /dev/null ; then
		_failure "risks" "/dev/mapper/${SDCARD_ENC_PART_MAPPER} can not be re-mounted with read-only permissions"
	fi

}

rw_hush()
{
	global_var_check "SDCARD_ENC_PART"
	global_var_check "SDCARD_ENC_PART_MAPPER"
	global_var_check "HUSH_DIR"

	if ! is_hush_mounted ; then
                _failure "risks" "SDCARD is not mounted"
		exit 1
	fi

	mount_option="remount,rw"

	if ! sudo mount -o ${mount_option} /dev/mapper/${SDCARD_ENC_PART_MAPPER} ${HUSH_DIR} &> /dev/null ; then
		_failure "risks" "/dev/mapper/${SDCARD_ENC_PART_MAPPER} can not be re-mounted with write permissions"
		exit 1
	fi

	sudo chown ${USER} ${HUSH_DIR}
}

is_luks_open()
{
	ls /dev/mapper/${1} &> /dev/null
}

is_luks_mounted()
{
	mount | grep "^${1}" &> /dev/null
}
