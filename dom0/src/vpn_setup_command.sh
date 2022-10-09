
_set_identity 

local name config_vm client_conf_path netvm

name="${args[vm]}"
config_vm="${args[--config-in]}"
client_conf_path="$(config_or_flag "" DEFAULT_VPN_CLIENT_CONF)"
netvm="$(config_or_flag "${args[--netvm]}" DEFAULT_NETVM)"

# There are different ways to setup a VPN VM, often mutually exclusive.

# We might be asked to change the netVM, but this can be combined
# with other settings to be handled below.
if [[ -n "${netvm}" ]]; then
    _message "Getting network from $netvm"
    qvm-prefs "$name" netvm "$netvm"
fi

# If the user wants this VM to be the default NetVM for all clients
# like browsers, messaging VMs, etc.
if [[ ${args[--set-default]} -eq 1 ]]; then
    echo "$name" > "${IDENTITY_DIR}/net_vm" 
    _message "Setting '$name' as default NetVM for all client machines"

    # Here, find all existing client VMs (not gateways) 
    # and change their netVMs to this one.
    local clients=($(_identity_client_vms))
    for client in "${clients[@]}"; do
        if [[ -n "$client" ]]; then
            _verbose "Changing $client netVM"
            qvm-prefs "$client" netvm "$name"
        fi
    done
fi

# Client VPN Configurations
if [[ "${args[--choose]}" -eq 1 ]]; then
    # If we are asked to choose an existing configuration in the VM
    _qvrun "$name" /usr/local/bin/setup_VPN 
elif [[ -n "${config_vm}" ]]; then
    # Or if we are asked to browse one or more configuration files in another VM.
    import_vpn_configs "$name" "$config_vm" "$client_conf_path"
fi
