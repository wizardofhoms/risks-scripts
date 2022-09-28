
if ! is_partition_mapper_present ; then
    _failure "risks" "Device mapper /dev/mapper/${SDCARD_ENC_PART_MAPPER} not found.\n \
    Be sure you have attached your hush partition."
fi

if is_hush_mounted ; then
    if ! sudo umount -f "${HUSH_DIR}" ; then
        _failure "risks" "/dev/mapper/${SDCARD_ENC_PART_MAPPER} can not be umounted from ${HUSH_DIR}"
    fi
fi

if is_luks_mapper_present ; then
    if ! sudo cryptsetup close "${SDCARD_ENC_PART_MAPPER}" ; then
        _failure "risks" "SDCARD can not be closed"
    fi
fi

play_sound "unplugged"
