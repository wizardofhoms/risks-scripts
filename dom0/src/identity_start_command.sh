
_set_identity "${args[identity]}"

# Get the name for VMs
local identity_dir="${IDENTITY_DIR}"
local name="$(cat "${identity_dir}/vm_name")"


