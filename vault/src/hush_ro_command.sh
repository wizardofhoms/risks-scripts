if ! is_hush_mounted ; then
    _failure "HUSH is not mounted"
fi

mount_option="remount,ro"
if ! sudo mount -o ${mount_option} "/dev/mapper/${SDCARD_ENC_PART_MAPPER}" "${HUSH_DIR}" &> /dev/null ; then
    _failure "/dev/mapper/${SDCARD_ENC_PART_MAPPER} can not be re-mounted with read-only permissions"
fi

_message "HUSH is now mounted read-only"
