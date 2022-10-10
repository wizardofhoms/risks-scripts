
# Creates a new Messaging AppVM.
# $1 - Name to use for new VM
# $2 - Netvm for this VM 
# $3 - Label
create_messenger_vm ()
{
    local msg="${1}-msg"
    local netvm="${2-$(config_get DEFAULT_NETVM)}"
    local gw_label="${3-orange}"

    local ws_template="$(config_get WHONIX_WS_TEMPLATE)"

    local -a create_command
    create_command+=(qvm-create --property netvm="$netvm" --label "$gw_label" --template "$ws_template")

    _message "Creating messaging VM (name: $msg / netvm: $netvm / template: $ws_template)"
}

# very similar to create_messenger_vm , except that we clone 
# an existing AppVM instead of creating a new one from a Template.
clone_messenger_vm ()
{
    local msg="${1}-msg"
    local gw_clone="$2"
    local netvm="${3-$(config_get DEFAULT_NETVM)}"
    local gw_label="${4-orange}"

    create_command+=(qvm-clone "${gw_clone}" "${msg}")

    local label_command=(qvm-prefs "$msg" label "$gw_label")
    local netvm_command=(qvm-prefs "$msg" netvm "$netvm")

    _message "Cloning messaging VM (name: $msg / netvm: $netvm / template: $gw_clone)"
}
