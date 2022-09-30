
RESOURCE="${args[resource]}"   # Resource is a tomb file (root directory) in ~/.tomb
DEST_VM="${args[dest_vm]}"    
IDENTITY="${args[identity]}"

identity="$(_identity_active_or_specified "${IDENTITY}")"

# Open the related tomb for the tool 
master_pass=$(get_passphrase "${identity}")
_run open_tomb "${RESOURCE}" "${identity}" "${master_pass}" 
_catch "Failed to open tomb"

# Get the source directory, and copy the files to the VM
_message "Loading data in tomb ${RESOURCE} to VM ${DEST_VM}"
source_dir="${HOME}/.tomb/${RESOURCE}"
_message "$(qvm-copy-to-vm "${DEST_VM}" "${source_dir}/"'*')"

# And close tomb if asked to
if [[ "${args[--close-tomb]}" -eq 1 ]]; then
    _message "Closing tomb"
    _run close_tomb "${RESOURCE}" "${identity}" "${master_pass}"
fi
