
# Creates a new TOR Whonix gateway AppVM.
# $1 - Name to use for new VM
# $2 - Netvm for this gateway
# $3 - Label
create_tor_gateway ()
{
    local gw="${1}-gw"
    local netvm="${2-$(config_get DEFAULT_NETVM)}"
    local gw_label="${3-yellow}"

    local gw_template="$(config_get WHONIX_GW_TEMPLATE)"

    local -a create_command
    create_command+=(qvm-create --property netvm="$netvm" --label "$gw_label" --template "$gw_template")

    _message "Creating TOR gateway VM (name: $gw / netvm: $netvm / template: $gw_template)"
}

# very similar to create_tor_gateway, except that we clone an existing
# gateway AppVM instead of creating a new one from a Template.
clone_tor_gateway ()
{
    local gw="${1}-gw"
    local gw_clone="$2"
    local netvm="${3-$(config_get DEFAULT_NETVM)}"
    local gw_label="${4-yellow}"

    create_command+=(qvm-clone "${gw_clone}" "${gw}")

    local label_command=(qvm-prefs "$gw" label "$gw_label")
    local netvm_command=(qvm-prefs "$gw" netvm "$netvm")

    _message "Cloning TOR gateway VM (name: $gw / netvm: $netvm / template: $gw_clone)"
}
