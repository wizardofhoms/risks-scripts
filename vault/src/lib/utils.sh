
# Return 0 if is set, 1 otherwise
option_is_set() {
	local -i r	 # the return code (0 = set, 1 = unset)

	[[ -n ${(k)OPTS[$1]} ]];
	r=$?

	[[ $2 == "out" ]] && {
		[[ $r == 0 ]] && { print 'set' } || { print 'unset' }
	}

	return $r;
}

# Plays sounds
# Package `sox` provides the "play" program: sudo apt-get install sox
play_sound()
{
	if [ ${SDCARD_QUIET} -gt 0 ] || [ ! -x "$(command -v play)" ]; then
		return 1
	fi

	case $1 in

		plugged)
			if [ -f /usr/share/sounds/freedesktop/stereo/device-added.oga ]; then
				play -V0 /usr/share/sounds/freedesktop/stereo/device-added.oga &> /dev/null
			fi
		;;

		unplugged)

			if [ -f /usr/share/sounds/freedesktop/stereo/device-removed.oga ]; then
				play -V0 /usr/share/sounds/freedesktop/stereo/device-removed.oga &> /dev/null
			fi
		;;

		*)
			return 1
		;;
	esac
}
