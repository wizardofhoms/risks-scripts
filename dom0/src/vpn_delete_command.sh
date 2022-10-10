
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

# If the VPN was the default NetVM for the identity,
# update the NetVM to Whonix.
netvm="$(cat "${IDENTITY_DIR}/net_vm")"
if [[ $netvm == "$name" ]]; then
    _warning "Gateway $name is the default NetVM for identity clients !"

    # Check if we have a TOR gateway
    local tor_gw

    if [[ -n $tor_gw ]]; then
        _message -n "Updating the default identity NetVM to $tor_gw"
    else
        _message -n "The identity has no default NetVM anymore, please set it."
    fi
fi

# Check if there are some existing VMs that use this gateway as NetVM,
# and change their netVM to None: this is unpractical, especially for
# those that might be up, but it's better than assigning a new netVM
# despite this presenting a security risk.

# Delete without asking to confirm
echo "y" | _run qvm-remove "$name"
_catch "Failed to delete (fully or partially) VM $name"

# Remove from VMs marked autostart
sed -i /"$name"/d "${IDENTITY_DIR}/autostart_vms"
# And remove from proxy VMs 
sed -i /"$name"/d "${IDENTITY_DIR}/proxy_vms"


_message "Deleted $name"
