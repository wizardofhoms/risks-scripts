local block="${args[device]:-$(config_get BACKUP_BLOCK)}"
local vm="$(config_get VAULT_VM)"

local sdcard_block="$(config_get SDCARD_BLOCK)"

qvm-block detach "${vm}" "${block}"
if [[ $? -eq 0 ]]; then
	_success "Block ${sdcard_block} has been detached from to ${vm}"
else
	_success "Block ${sdcard_block} can not be detached from ${vm}"
fi

