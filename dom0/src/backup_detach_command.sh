local block="${BACKUP_BLOCK}"
local vm="${VAULT_VM}"

qvm-block detach "${vm}" "${block}"
if [[ $? -eq 0 ]]; then
	_success "Block ${SDCARD_BLOCK} has been detached from to ${vm}"
else
	_success "Block ${SDCARD_BLOCK} can not be detached from ${vm}"
fi

