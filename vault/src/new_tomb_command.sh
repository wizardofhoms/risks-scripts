
LABEL="${args[tomb_name]}"
SIZE="${args[size]}"
IDENTITY="$(_identity_active_or_specified "${args[identity]}")"

_message "Creating tomb ${LABEL} with size ${SIZE}M"

# Master passphrase for file encryption
master_pass=$(get_passphrase "${IDENTITY}")

# And GPG passphrase needed by prompts
gpg_passphrase=$(get_passphrase "${IDENTITY}" "${GPG_TOMB_LABEL}" "${master_pass}")
echo -n "${gpg_passphrase}" | xclip -loops 1 -selection clipboard
_warning "Passphrase copied to clipboard, with one time use only, for upcoming GPG prompt"

_run new_tomb "${LABEL}" "${SIZE}" "${IDENTITY}" "${master_pass}" 
_catch "Failed to create tomb"
_message "Done creating tomb."
