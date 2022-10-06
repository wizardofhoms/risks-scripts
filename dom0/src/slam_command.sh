
# Get the active identity
local active_identity=$(qvm-run --pass-io "$VAULT_VM" 'cat .identity' 2>/dev/null)
if [[ -z $active_identity ]]; then
    _message "No active identity to close"
    exit 0
fi

# Find all VMs linked to that identity;
# 1 - Web browsers/ appVMs
# 2 - NetVMs ; VPNs and gateway

# Slam the identity
_message "Slamming infrastructure, vault and devices: identity $active_identity"

_success "Done"
