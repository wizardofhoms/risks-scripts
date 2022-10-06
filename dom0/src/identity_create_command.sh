
local identity="${args[identity]}"

# Identity checks and basic setup ==========================================

# First open the identity, because we might need its credentials and stuff
# The identity argument is here, so this command has the arguments it needs
active_identity=$(qvm-run --pass-io "$VAULT_VM" 'cat .identity' 2>/dev/null)
if [[ -n $active_identity ]]; then
    # It might be the same
    if [[ $active_identity != "$identity" ]]; then
        _failure "Another identity ($identity) is active. Close/slam/fold it and rerun this command"
    fi
else
    risk_open_identity_command
    _catch "Failed to open identity $identity"
fi


# Make a directory for this identity, and store the associated VM name
local identity_dir="${RISK_IDENTITIES_DIR}/$identity"
[[ -e ${identity_dir} ]] || mkdir -p "$identity_dir"

# Else we're good to go
_message "Initializing infrastructure for identity $identity"

# Default settings and values ==============================================

# If the user wants to use a different name for the VMs
local name="${args[--name]-$identity}"
echo "$name" > "${identity_dir}/vm_name" 
_message "Using name '$name' as VM base name"

local label="${args[--label]}"

# Prepare the root NetVM for this identity

# Network VMs ==============================================================
_message "Creating network VMs:"

# 1 - Tor gateway, if not explicitly disabled
if [[ ${args[--no-gw]} -eq 0 ]]; then
    local gw_netvm

    # We either clone the gateway from an existing one,
    # or we create it from a template.
    if [[ -n ${args[--clone-gw-from]} ]]; then
        local clone="${args[--clone-gw-from]}"
        clone_tor_gateway "$name" "$clone" "$gw_netvm" "$label"
    else
        create_tor_gateway "$name" "$gw_netvm" "$label"
    fi
else
    _message "Skipping TOR gateway"
fi

# 2 - VPNs, if not explicitly disabled
if [[ ${args[--no-vpn]} -eq 0 ]]; then
    local vpn_netvm

    # We either clone the gateway from an existing one,
    # or we create it from a template.
    if [[ -n ${args[--clone-vpn-from]} ]]; then
        local clone="${args[--clone-vpn-from]}"
        clone_vpn_gateway "$name" "$clone" "$vpn_netvm" "$label"
    else
        create_vpn_gateway "$name" "$vpn_netvm" "$label"
    fi
else
    _message "Skipping VPN gateway"
fi

# 3 - Setting up the network routes
if [[ ${args[--vpn-over-tor]} -eq 1 ]]; then
    echo
fi

# At this point we should know the name of the VM to be used as NetVM
# for the subsquent machines, such as web browsing and messaging VMs.

# Message VMs ==============================================================
_message "Creating messaging VMs:"

if [[ ${args[--no-messenger]} -eq 0 ]]; then
    local msg="${name}-msg"
else
    _message "Skipping messaging VM"
fi


# Browser VMs ==============================================================
_message "Creating web VMs:"

# Browser VMs are disposable, but we make a template for this identity,
# since we might  either modify stuff in there, and we need them at least 
# to have a different network route.
if [[ -n ${args[--clone-web-from]} ]]; then
    local web_netvm

    local clone="${args[--clone-web-from]}"
    clone_browser_vm "$name" "$clone" "$web_netvm" "$label"
else
    create_browser_vm "$name" "$web_netvm" "$label"
fi

# Split-browser has its own dispVMs and bookmarks
local split_web="${name}-split-web"
if [[ -n ${args[--clone-split-from]} ]]; then
    local clone="${args[--clone-split-from]}"
    clone_split_browser_vm "$name" "$clone" "$label"
else
    create_split_browser_vm "$name" "$label"
fi


## All done ##
_success "Successfully initialized infrastructure for identity $identity"
