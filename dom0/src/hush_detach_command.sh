
local block vm

block="${args[device]-$SDCARD_BLOCK}"
vm="${args[vault_vm]-$VAULT_VM}"

# First unmount the hush device in vault
_qrun "$vm" risks hush umount
_catch "Failed to unmount hush device ($block)"

# finally attach the sdcard encrypted partition to the qube
qvm-block detach "${vm}" "${block}"
if [[ $? -eq 0 ]]; then
	_success "Block ${block} has been detached from ${vm}"
else
	_failure "Block ${block} can not be detached from ${vm}"
fi

