
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
    if ! sudo cryptsetup open --type luks "${SDCARD_ENC_PART}" "${SDCARD_ENC_PART_MAPPER}" ; then
        _failure "hush" "The hush partition ${SDCARD_ENC_PART} can not be decrypted"
        exit 1
    fi
fi

# creates the "hush partition" mount point if it doesn't exist
if [ ! -d "${HUSH_DIR}" ]; then
    mkdir -p "${HUSH_DIR}" &> /dev/null
fi

# mounts the "hush partition" in read-only mode by default
if ! sudo mount -o ro "/dev/mapper/${SDCARD_ENC_PART_MAPPER}" "${HUSH_DIR}" ; then
    _failure "hush" "/dev/mapper/${SDCARD_ENC_PART_MAPPER} can not be mounted on ${HUSH_DIR}"
    exit 1
fi

play_sound "plugged"
