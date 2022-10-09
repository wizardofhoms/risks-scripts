
local name="${args[vm]}"

_message "Starting gateway $name in the background"
start_vm "$name"
_catch "Failed to start $name"
_message "Started VM $name"
