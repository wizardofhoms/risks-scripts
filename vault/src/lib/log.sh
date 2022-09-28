
function is_verbose_set () {
    if [[ "${args[--verbose]}" -eq 1 ]]; then
        return 0
    else
        return 1
    fi
}

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

    ${=command} "${progname}" "${pchars}" "${msg}" >&"$fd"
	return $returncode
}

function _message() {
	local notice="message"
	[[ "$1" = "-n" ]] && shift && notice="inline"
    option_is_set -q || _msg "$notice" "$@"
	return 0
}

function _verbose() {
    is_verbose_set && _msg verbose "$@"
    # option_is_set -D && _msg verbose "$@"
	return 0
}

function _success() {
    option_is_set -q || _msg success "$@"
	return 0
}

function _warning() {
    option_is_set -q || _msg warning "$@"
	return 1
}

function _failure() {
    local section="$1"
    shift
    
	typeset -i exitcode=${exitv:-1}

    _msg failure "$section" "$@"               # First print the failure message info we passed
    _message "$section" "$COMMAND_STDERR"   # And then print the command's failure message itself

	# Be sure we forget the secrets we were told
    exit "$exitcode"
}

# function _failure() {
# 	typeset -i exitcode=${exitv:-1}
#     option_is_set -q || _msg failure "$@"
# 	# be sure we forget the secrets we were told
#     exit "$exitcode"
# }

function _print() {
    option_is_set -q || _msg print "$@"
	return 0
}

# Variables

COMMAND_STDOUT=''           # Stores a command's stdout output.
COMMAND_STDERR=''           # Stores a command's stderr output.   

# do a command, splitting and storing stdout/stderr output and printing
# the former to screen only if the command is ran with verbose flag.
# Returns the command's exit code, so we can catch any errors and inform.
_run ()
{
    # First argument is the name of the section
    local section="$1"
    shift

    # The STDOUT/STDERR variables are populated, which
    # makes their content available to any subsequent call
    # to _failure, which needs STDERR output
    {
        IFS=$'\n' read -r -d '' COMMAND_STDERR;
        IFS=$'\n' read -r -d '' COMMAND_STDOUT;
        (IFS=$'\n' read -r -d '' _ERRNO_; exit "${_ERRNO_}");
    } < <((printf '\0%s\0%d\0' "$("$@")" "${?}" 1>&2) 2>&1)

    local ret="$?"

    # Output the command's result depending on the verbose mode
    # and if the command ran successfully.
    if [[ $ret -eq 0 ]] && is_verbose_set ; then
        _verbose "$section" "$COMMAND_STDOUT"
    fi

    # Return the command's exit code
    return $ret
}

# Checks the return code of a command, and if not successful,
# fails with the associated error message. Usage:
# catch $ret "hush" "Failed to execute this command"
function _catch ()
{
    local ret="$?" 
    local section="$1"
    shift 

    if [[ ! $ret -eq 0 ]]; then
        _failure "$section" "$@"
    fi
}

