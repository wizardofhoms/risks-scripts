if ! is_hush_mounted ; then
            _failure "SDCARD is not mounted"
    exit 1
fi

mount_option="remount,rw"
if ! sudo mount -o ${mount_option} "/dev/mapper/${SDCARD_ENC_PART_MAPPER}" "${HUSH_DIR}" &> /dev/null ; then
    _failure "/dev/mapper/${SDCARD_ENC_PART_MAPPER} can not be re-mounted with write permissions"
    exit 1
fi

sudo chown "${USER}" "${HUSH_DIR}"

_warning "/----------------------------------------/"
_message -n "Warning! HUSH is writable              \n"
_message -n "Do not unplug without umounting it !   \n"
_message -n "/----------------------------------------/ \n"
