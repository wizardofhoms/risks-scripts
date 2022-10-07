
_set_identity 

# Prepare some settings for this new VM
local name netvm clone template label config config_path

name="${args[name]-$(cat "${IDENTITY_DIR}/vm_name" 2>/dev/null)}"
label="${args[--label]-$(get_identity_label)}"
netvm="$(config_or_flag "${args[--netvm]}" DEFAULT_NETVM)"
clone="$(config_or_flag "${args[--clone]}" VPN_VM)"
template="$(config_or_flag "${args[--template]}" VPN_TEMPLATE)"
config_vm="${args[--config-in]}"
client_conf_path="$(config_or_flag "" DEFAULT_VPN_CLIENT_CONF)"

# 1 - Creation
#
# We either clone the gateway from an existing one,
# or we create it from a template.
if [[ -n "${args[--clone]}" ]]; then
    _message "Cloning VPN gateway (from VM $clone)"
    clone_vpn_gateway "$name" "$netvm" "$label" "$clone" 
else
    _message "Creating VPN gateway (from template $template)"
    create_vpn_gateway "$name" "$netvm" "$label" "$template"
fi

# 2 - Setup
#
# Simply run the setup command, which has access to all the flags
# it needs to do its job.
risk_vpn_setup_command

_message "Done creating VPN gateway $name"
