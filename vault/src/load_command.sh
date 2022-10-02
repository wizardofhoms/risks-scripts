
RESOURCE="${args[resource]}"   # Resource is a tomb file (root directory) in ~/.tomb
DEST_VM="${args[dest_vm]}"    

_set_identity "${args[identity]}"

# Open the related tomb for the tool 
_run open_tomb "$RESOURCE"
_catch "Failed to open tomb"

# Get the source directory, and copy the files to the VM
_message "Loading data in tomb $RESOURCE to VM $DEST_VM"
local source_dir="${HOME}/.tomb/${RESOURCE}"
_message "$(qvm-copy-to-vm "$DEST_VM" "${source_dir}/"'*')"

# And close tomb if asked to
if [[ "${args[--close-tomb]}" -eq 1 ]]; then
    _message "Closing tomb"
    _run close_tomb "$RESOURCE"
fi
