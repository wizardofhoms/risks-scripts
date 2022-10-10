# gpgpass essentially wraps a call to spectre with our identity parameters.
# Note that this function cannot fail because of "a wrong password".
#
# If a second, non-nil argument is passed, we print the passphrase: 
# this is used when some commands need both the passphrase as an input
# to decrypt something (like files) and the user needs them for GPG prompts

declare timeout

# Identity is optionality specified as an argument
_set_identity "${args[identity]}"

# Since we did not give any input (master) passphrase to this call,
# spectre will prompt us for an input one. This input is already known
# to us, since we have used the same when generating the GPG keys.
#
# In addition: this call cannot fail because of "a wrong" passphrase.
# It will just output something, which will or will not (if actually incorrect)
# work when pasted in further GPG passphrase prompts.
GPG_PASS=$(get_passphrase "$GPG_TOMB_LABEL")

timeout="${args[--timeout]-$GPGPASS_TIMEOUT}"

echo -n "$GPG_PASS" | xclip -selection clipboard
( sleep "$timeout"; echo -n "" | xclip -selection clipboard;) &

_message "The passphrase has been saved in clipboard"
_message "Press CTRL+SHIFT+C to share the clipboard with another qube."
_message "Local clipboard will be erased is $timeout seconds"       
