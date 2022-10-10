
local vault_vm="$(config_get VAULT_VM)"

# Check we have an active identity
active_identity=$(qvm-run --pass-io "$vault_vm" 'cat .identity' 2>/dev/null)
if [[ -z $active_identity ]]; then
    _message "No active identity to close"
    exit 0
fi

_message "Closing identity $active_identity"

_qrun "$vault_vm" risks close identity "$active_identity"
_catch "Failed to close identity $active_identity"

_message "Identity $active_identity is closed"
