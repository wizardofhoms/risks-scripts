
local name="${args[vm]}"

_message "Shutting down gateway $name"
shutdown_vm "$name"
_catch "Failed to shutdown $name"
_message "Shut down $name"
