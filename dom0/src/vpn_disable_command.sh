
_set_identity 

local name="${args[vm]}"

_message "Disabling VM $name"
sed -i /"$name"/d "${IDENTITY_DIR}/autostart_vms"

