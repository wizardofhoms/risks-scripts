
_set_identity 

local name found proxies

name="${args[vm]}"

# Check that the selected VM is indeed one of the identity
# proxy VMs, so that we don't accidentally delete another one.
proxies=($(_identity_proxies))
for proxy in "${proxies[@]}" ; do
    if [[ $proxy == "$name" ]]; then
        found=true
    fi
done

if [[ ! $found ]]; then
    _message "VM $name is not listed as a VPN gateway. Aborting."
    exit 1
fi

_message "Deleting gateway VM $name"

# Delete without asking to confirm
echo "y" | _run qvm-remove "$name"
_catch "Failed to delete (fully or partially) VM $name"

# Remove from VMs marked autostart
sed -i /"$name"/d "${IDENTITY_DIR}/autostart_vms"
# And remove from proxy VMs 
sed -i /"$name"/d "${IDENTITY_DIR}/proxy_vms"

_message "Deleted $name"
