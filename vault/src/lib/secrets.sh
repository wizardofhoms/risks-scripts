
# _set_file_encryption_key is only called once per risks run,
# and does not need any password prompt to be used: it just generates
# a deterministic key based on known inputs.
_set_file_encryption_key ()
{
    local identity="$1"
    local key
    key=$(print "$identity" | spectre -q -n -s 0 -F n -t n -u "$identity" "$FILE_ENCRYPTION")
    print "$key"
}

# _encrypt_filename takes a filename as input, and uses the currently 
# set identity to produce an random name to use as a file/directory name.
_encrypt_filename ()
{
    local filename="$1"
    local encrypted

    # -q            Quiet: just output the password/filename
    # -n            Don't append a newline to the password output
    # -s 0          Read passphrase from stdinput (fd 0)
    # -F n          No config file output
    # -t n          Output a nine characters name, without symbols
    # -u ${user}    User for which to produce the password/name
    encrypted=$(print "$FILE_ENCRYPTION_KEY" | spectre -q -n -s 0 -F n -t n -u "$IDENTITY" "$filename")
    print "${encrypted}"
}

# Returns a spectre-generated secret key, given a single name as argument.
# Uses the current IDENTITY as set by _set_identity <identity_name>
get_passphrase ()
{
    local passname="${1}"

    local passphrase

    # Forge command
    local cmd=(spectre -q -n -F n)
    local spectre_params=(-t K -P 512 -u "$IDENTITY" "$passname")

    passphrase=$("${cmd[@]}" "${spectre_params[@]}")

    print "$passphrase"
}

## ====================== TAKEN FROM TOMB CODE ======================== ##

# _is_found() {
# 	# returns 0 if binary is found in path
# 	[[ -z $1 ]] && return 1
# 	command -v "$1" 1>/dev/null 2>/dev/null
# 	return $?
# }

# pinentry_assuan_getpass() {
# 	# simply prints out commands for pinentry's stdin to activate the
# 	# password dialog
# 	cat <<EOF
# OPTION ttyname=$TTY
# OPTION lc-ctype=$LANG
# SETTITLE $title
# SETDESC $description
# SETPROMPT Password:
# GETPIN
# EOF
# }
#
# # Ask user for a password
# # Wraps around the pinentry command, from the GnuPG project, as it
# # provides better security and conveniently use the right toolkit.
# ask_password() {
#
# 	local description="$1"
# 	local title="${2:-Enter tomb password.}"
# 	local output
# 	local password
# 	local gtkrc
# 	local theme
# 	local pass_asked
#
# 	# Distributions have broken wrappers for pinentry: they do
# 	# implement fallback, but they disrupt the output somehow.	We are
# 	# better off relying on less intermediaries, so we implement our
# 	# own fallback mechanisms. Pinentry supported: curses, gtk-2, qt4, qt5
# 	# and x11.
#
# 	# make sure LANG is set, default to C
# 	LANG=${LANG:-C}
#
# 	_verbose "asking password with tty=$TTY lc-ctype=$LANG"
#
# 	pass_asked=0
#
# 	if [[ -n $WAYLAND_DISPLAY ]]; then
# 		_verbose "wayland display detected"
# 		_is_found "pinentry-gnome3" && {
# 			_verbose "using pinentry-gnome3 on wayland"
# 			output=$(pinentry_assuan_getpass | pinentry-gnome3)
# 			pass_asked=1
# 		}
# 	fi
# 	if [[ -n $DISPLAY ]] && [[ $pass_asked == 0 ]]; then
# 		_verbose "X11 display detected"
# 		if _is_found "pinentry-gtk-2"; then
# 			_verbose "using pinentry-gtk2"
# 			output=$(pinentry_assuan_getpass | pinentry-gtk-2)
# 			pass_asked=1
# 		elif _is_found "pinentry-x11"; then
# 			_verbose "using pinentry-x11"
# 			output=$(pinentry_assuan_getpass | pinentry-x11)
# 			pass_asked=1
# 		elif _is_found "pinentry-gnome3"; then
# 			_verbose "using pinentry-gnome3 on X11"
# 			output=$(pinentry_assuan_getpass | pinentry-gnome3)
# 			pass_asked=1
# 		elif _is_found "pinentry-qt5"; then
# 			_verbose "using pinentry-qt5"
# 			output=$(pinentry_assuan_getpass | pinentry-qt5)
# 			pass_asked=1
# 		elif _is_found "pinentry-qt4"; then
# 			_verbose "using pinentry-qt4"
# 			output=$(pinentry_assuan_getpass | pinentry-qt4)
# 			pass_asked=1
# 		fi
# 	fi
# 	if [[ $pass_asked == 0 ]]; then
# 		_verbose "no display detected"
# 		_is_found "pinentry-curses" && {
# 			_verbose "using pinentry-curses with no display"
# 			output=$(pinentry_assuan_getpass | pinentry-curses)
# 			pass_asked=1
# 		}
# 	fi
#
# 	[[ $pass_asked == 0 ]] &&
# 		_failure "Cannot find any pinentry-curses and no DISPLAY detected."
#
# 	# parse the pinentry output
# 	local pinentry_error
# 	for i in ${(f)output}; do
# 		[[ "$i" =~ "^ERR.*" ]] && {
# 			pinentry_error="${i[(w)3]}"
# 		}
#
# 		# here the password is found
# 		[[ "$i" =~ "^D .*" ]] && password="${i##D }";
# 	done
#
# 	[[ ! -z $pinentry_error ]] && [[ -z $password ]] && {
#         _warning "Pinentry error: ::1 error::" "${pinentry_error}"
# 		print "canceled"
# 		return 1
# 	}
#
# 	[[ -z $password ]] && {
# 		_warning "Empty password"
# 		print "empty"
# 		return 1
# 	}
#
# 	print "$password"
# 	return 0
# }
