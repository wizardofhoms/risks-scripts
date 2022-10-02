
LABEL="${args[tomb_name]}"
SIZE="${args[size]}"

_set_identity "${args[identity]}"

_message "Creating tomb $LABEL with size ${SIZE}M"

# # And GPG passphrase needed by prompts
# gpg_passphrase=$(get_passphrase "$GPG_TOMB_LABEL")
# echo -n "$gpg_passphrase" | xclip -loops 1 -selection clipboard
# _warning "Passphrase copied to clipboard, with one time use only, for upcoming GPG prompt"
#
_run new_tomb "$LABEL" "$SIZE"
_catch "Failed to create tomb"
_message "Done creating tomb."
