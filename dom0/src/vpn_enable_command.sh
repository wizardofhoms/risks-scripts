
_set_identity 

local name autostart_vms already_enabled

name="${args[vm]}"
autostart_vms=($(_identity_autostart_vms))

# Check if the VM is already marked autostart
for proxy in "${autostart_vms[@]}" ; do
    if [[ $proxy == "$name" ]]; then
        already_enabled=true
    fi
done

if [[ ! $already_enabled ]]; then
    _message "Enabling VM ${name} to autostart"
    echo "$name" >> "${IDENTITY_DIR}/autostart_vms"
else
    _message "VM ${name} is already enabled"
fi
