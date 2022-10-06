
local identity="${args[identity]}"

# Get the name for VMs
local identity_dir="${RISK_IDENTITIES_DIR}/$identity"
local name="$(cat "${identity_dir}/vm_name")"


