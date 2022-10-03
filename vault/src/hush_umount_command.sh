
if ! is_named_partition_mapper_present "${SDCARD_ENC_PART_MAPPER}" ; then
    _failure "Device mapper /dev/mapper/${SDCARD_ENC_PART_MAPPER} not found.\n \
    Be sure you have attached your hush partition."
fi

if is_hush_mounted ; then
    if ! sudo umount -f "${HUSH_DIR}" ; then
        _failure "/dev/mapper/${SDCARD_ENC_PART_MAPPER} can not be umounted from ${HUSH_DIR}"
    fi
fi

if is_luks_mapper_present "${SDCARD_ENC_PART_MAPPER}" ; then
    if ! sudo cryptsetup close "${SDCARD_ENC_PART_MAPPER}" ; then
        _failure "SDCARD can not be closed"
    fi
fi

play_sound "unplugged"

_message "Hush device is unmounted and closed"
