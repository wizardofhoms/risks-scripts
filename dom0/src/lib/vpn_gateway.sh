#!/usr/bin/env bash 

# Creates a new VPN gateway from a TemplateVM
create_vpn_gateway ()
{
    local gw="${1}-gw"
    local netvm="${2-$RISK_DEFAULT_NETVM}"
    local gw_label="${3-blue}"

    local -a create_command
    create_command+=(qvm-create --property netvm="$netvm" --label "$gw_label" --template "$RISK_VPN_TEMPLATE")

    _message "Creating VPN gateway VM (name: $gw / netvm: $netvm / template: $RISK_VPN_TEMPLATE)"
}

# Creates a new VPN gateway from an existing VPN AppVM 
clone_vpn_gateway ()
{
    local gw="${1}-vpn"
    local gw_clone="$2"
    local netvm="${3-$RISK_DEFAULT_NETVM}"
    local gw_label="${4-blue}"

    # Create the VPN
    local -a create_command
    create_command+=(qvm-clone "${gw_clone}" "${gw}")

    local label_command=(qvm-prefs "$gw" label "$gw_label")
    local netvm_command=(qvm-prefs "$gw" netvm "$netvm")

    _message "Cloning VPN gateway VM (name: $gw / netvm: $netvm / template: $gw_clone)"

    # For now disposable are not allowed, since it would create too many VMs, 
    # and complicate a bit the setup steps for VPNs. If the clone is a template
    # for disposables, unset it
    local disp_template
    # disp_template=$(qvm-prefs "${gw}" template_for_dispvms)
    # [[ "$disp_template" = "True" ]] && qvm-prefs "${gw}" template_for_dispvms False
}
