
LABEL="${args[tomb_name]}"
SIZE="${args[size]}"

_set_identity "${args[identity]}"

_message "Creating tomb $LABEL with size ${SIZE}M"

_run new_tomb "$LABEL" "$SIZE"
_catch "Failed to create tomb"

_message "Done creating tomb."
