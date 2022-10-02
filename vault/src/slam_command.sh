
# First set the identity variables with the active one. 
_set_identity ""

_warning "risks" "Slaming identity $IDENTITY"

_run slam_tomb "$SIGNAL_TOMB_LABEL"

_message "Slaming PASS tomb ..."
_run slam_tomb "$PASS_TOMB_LABEL"

_message "Slaming SSH tomb ..."
_run slam_tomb "$SSH_TOMB_LABEL"

_message "Slaming Management tomb ..."
_run slam_tomb "$MGMT_TOMB_LABEL"

_message "Closing GPG coffin ..."
close_coffin
# done

# Finally, find all other tombs...
tombs=$(tomb list 2>&1 \
    | sed -n '0~4p' \
    | awk -F" " '{print $(3)}' \
    | rev | cut -c2- | rev | cut -c2-)

# ... and close them
while read -r tomb_name ; do
    _message "Slaming tomb $tomb_name ..."
    _run tomb slam "$tomb_name"
done <<< "$tombs"

# 3 - Unmount hush
echo
_message "Unmounting hush partition"
_run risks_hush_umount_command
_catch "Failed to unmount hush partition"
