# 1 - Get all open identities
identities=$(list_coffins | sed -n '1!p') # Remove first line, not an identity
identities=("${identities[@]}") 

# 2 - Close them all
for identity in "${identities[@]}"; do

    # First get the master passphrase for the identity
    master_pass=$(get_passphrase "${identity}")

    _warning "risks" "Slaming identity ${identity}"

    _run slam_tomb "${SIGNAL_TOMB_LABEL}" "${identity}" "${master_pass}"

    _message "Slaming PASS tomb ..."
    _run slam_tomb "${PASS_TOMB_LABEL}" "${identity}" "${master_pass}"

    _message "Slaming SSH tomb ..."
    _run slam_tomb "${SSH_TOMB_LABEL}" "${identity}" "${master_pass}"

    _message "Slaming Management tomb ..."
    _run slam_tomb "${MGMT_TOMB_LABEL}" "${identity}" "${master_pass}"

    _message "Closing GPG coffin ..."
    close_coffin "${identity}" "${master_pass}"
done

# Finally, find all other tombs...
tombs=$(tomb list 2>&1 \
    | sed -n '0~4p' \
    | awk -F" " '{print $(3)}' \
    | rev | cut -c2- | rev | cut -c2-)

# ... and close them
while read -r tomb_name ; do
    _message "Slaming tomb ${tomb_name} ..."
    _run tomb slam "${tomb_name}"
done <<< "$tombs"

# 3 - Unmount hush
echo
_messge "Unmounting hush partition"
_run risks_hush_umount_command
_catch "Failed to unmount hush partition"
