
# Messaging function with pretty coloring
function _msg() 
{
    local progname="$2"
	local msg="$3"
	local i
	command -v gettext 1>/dev/null 2>/dev/null && msg="$(gettext -s "$3")"
	for i in {3..${#}}; do
		msg=${(S)msg//::$(($i - 2))*::/$*[$i]}
	done

	local command="print -P"
	local pchars=""
	local pcolor="normal"
	local fd=2
	local -i returncode

	case "$1" in
		inline)
			command+=" -n"; pchars=" > "; pcolor="yellow"
			;;
		message)
			pchars=" . "; pcolor="white"
			;;
		verbose)
			pchars="[D]"; pcolor="blue"
			;;
		success)
			pchars="(*)"; pcolor="green"
			;;
		warning)
			pchars="[W]"; pcolor="yellow"
			;;
		failure)
			pchars="[E]"; pcolor="red"
			returncode=1
			;;
		print)
			progname=""
			fd=1
			;;
		*)
			pchars="[F]"; pcolor="red"
			msg="Developer oops!  Usage: _msg MESSAGE_TYPE \"MESSAGE_CONTENT\""
			returncode=127
			;;
	esac

	[[ -n $_MSG_FD_OVERRIDE ]] && fd=$_MSG_FD_OVERRIDE

	if [[ -t $fd ]]; then
	       [[ -n "$progname" ]] && progname="$fg[magenta]$progname$reset_color"
	       [[ -n "$pchars" ]] && pchars="$fg_bold[$pcolor]$pchars$reset_color"
	       msg="$fg[$pcolor]$msg$reset_color"
	fi

	${=command} "${progname}" "${pchars}" "${msg}" >&$fd
	return $returncode
}

function _message() {
	local notice="message"
	[[ "$1" = "-n" ]] && shift && notice="inline"
	option_is_set -q || _msg "$notice" $@
	return 0
}

function _verbose() {
	option_is_set -D && _msg verbose $@
	return 0
}

function _success() {
	option_is_set -q || _msg success $@
	return 0
}

function _warning() {
	option_is_set -q || _msg warning $@
	return 1
}

function _failure() {
	typeset -i exitcode=${exitv:-1}
	option_is_set -q || _msg failure $@
	# be sure we forget the secrets we were told
	exit $exitcode
}

function _print() {
	option_is_set -q || _msg print $@
	return 0
}

