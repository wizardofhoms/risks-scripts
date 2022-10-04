
# Checks that a given device is attached to a given VM
check_is_device_attached ()
{
    local block="$1"
    local vm="$2"

    local ovm=$(qvm-block list | grep "${block}" | awk {'print $4'} | cut -d" " -f1)
    if [[ ${#ovm} -eq 0 ]] || [[ ${ovm} != "$vm" ]]; then
        _failure "Device block $block is not mounted on vault ${vm}"
    fi
}
