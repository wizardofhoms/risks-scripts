
label="${args[tomb_name]}"
size="${args[size]}"

# We need the hush device, on which to save the key
if ! is_luks_mapper_present "${SDCARD_ENC_PART_MAPPER}" ; then
    _failure "Hush device not mounted. Need access to write tomb key in it."
fi

_set_identity "${args[identity]}"

_message "Creating tomb $label with size ${size}M"

# This new key is also the one provided when using gpgpass command.
GPG_PASS=$(get_passphrase "$GPG_TOMB_LABEL")
echo -n "$GPG_PASS" | xclip -loops 1 -selection clipboard
_warning "GPG passphrase copied to clipboard with one-time use only"
_message -n "Copy it in the coming GPG prompt when creating the tomb.\n"

_run new_tomb "$label" "$size"
_catch "Failed to create tomb"

_message "Done creating tomb."
