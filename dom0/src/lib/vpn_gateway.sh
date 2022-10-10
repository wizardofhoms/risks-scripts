
# Creates a new VPN gateway from a TemplateVM
create_vpn_gateway ()
{
    local gw="${1}"
    local netvm="${2-$(config_get DEFAULT_NETVM)}"
    local gw_label="${3:=blue}"
    local template="${4:=$(config_get VPN_TEMPLATE)}"

    _verbose "VPN gateway properties (name: $gw / netvm: $netvm / template: $template)"
    qvm-create --property netvm="$netvm" --label "$gw_label" --template "$template"

    _message "Getting network from $netvm"

    # Add the gateway to the list of existing proxies for this identity
    echo "$gw" >> "${IDENTITY_DIR}/proxy_vms"
}

# Creates a new VPN gateway from an existing VPN AppVM 
clone_vpn_gateway ()
{
    local gw="${1}"
    local netvm="${2-$(config_get DEFAULT_NETVM)}"
    local gw_label="${3:=blue}"
    local gw_clone="$4"

    # Create the VPN
    _verbose "VPN gateway properties (name: $gw / netvm: $netvm / clone: $gw_clone)"
    _run qvm-clone "${gw_clone}" "${gw}"
    _catch "Failed to clone VM ${gw_clone}"

    # For now disposables are not allowed, since it would create too many VMs, 
    # and complicate a bit the setup steps for VPNs. If the clone is a template
    # for disposables, unset it
    local disp_template
    disp_template=$(qvm-prefs "${gw}" template_for_dispvms)
    [[ "$disp_template" = "True" ]] && qvm-prefs "${gw}" template_for_dispvms False

    # _message "Getting network from $netvm"
    qvm-prefs "$gw" netvm "$netvm"

    _verbose "Setting label to $gw_label"
    qvm-prefs "$gw" label "$gw_label"

    # Add the gateway to the list of existing proxies for this identity
    echo "$gw" >> "${IDENTITY_DIR}/proxy_vms"
}

# function to browse for one or more (as zip) VPN client configurations
# in another VM, import them in our VPN VM, and run the setup wizard if
# there is more than one configuration to choose from.
# $1 - Name of VPN VM
# $2 - Name of VM in which to browse for configuration
# $ $3 - Path to the VPN client config to which one (only) should be copied, if not a zip file
import_vpn_configs ()
{
    local name="$1"
    local config_vm="$2"
    local client_conf_path="$3"

    config_path=$(_qvrun "$config_vm" "zenity --file-selection --title='VPN configuration selection' 2>/dev/null")
    if [[ -z "$config_path" ]]; then
        _message "Canceling setup: no file selected in VM $config_vm"
    else
        _verbose "Copying file $config_path to VPN VM"
        _qvrun "$config_vm" qvm-copy-to-vm "$name" "$config_path"

        # Now our configuration is the QubesIncoming directory of our VPN,
        # so we move it where the VPN will look for when starting.
        local new_path="/home/user/QubesIncoming/${config_vm}/$(basename "$config_path")"

        # If the file is a zip file, unzip it in the configs directory
        # and immediately run the setup prompt to choose one.
        if [[ $new_path:t:e == "zip" ]]; then
            local configs_dir="/rw/config/vpn/configs" 
            _verbose "Unzipping files into $configs_dir"
            _qvrun "$name" mkdir -p "$configs_dir" 
            _qvrun "$name" unzip -j -d "$configs_dir" 
            _qvrun "$name" /usr/local/bin/setup_VPN 
        else
            _verbose "Copying file directly to the VPN client config path"
            _qvrun "$name" mv "$new_path" "$client_conf_path"
        fi

        _message "Done transfering VPN client configuration to VM"
    fi

    # Add the gateway to the list of existing proxies for this identity
    echo "$gw" > "${IDENTITY_DIR}/proxy_vms"
}

# get_next_vpn_name returns a name for a new VPN VM, such as vpn-1,
# where the number is the next value after the ones found in existing
# VPN vms.
get_next_vpn_name ()
{
    local base_name="$1"

    # First get the array of ProxyVMs names
    local proxies=($(_identity_proxies))

    local next_number=1

    for proxy in "${proxies[@]}"; do
        if contains "$proxy" "vpn-"; then
            next_number=$((next_number + 1))
        fi
    done

    print "$1-vpn-$next_number"
}
