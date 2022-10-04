
COMMAND_STDOUT=''           # Stores a command's stdout output.
COMMAND_STDERR=''           # Stores a command's stderr output.   

# do a command, splitting and storing stdout/stderr output and printing
# the former to screen only if the command is ran with verbose flag.
# Returns the command's exit code, so we can catch any errors and inform.
_run ()
{
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
    # and if the command ran successfully. We check that either
    # stdout or stderr are non-empty: sometimes commands might
    # output to stderr, like wipe.
    if [[ $ret -eq 0 ]] && is_verbose_set ; then
        if [[ -n "$COMMAND_STDOUT" ]]; then
            _verbose "$COMMAND_STDOUT"
        fi
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

    if [[ ! $ret -eq 0 ]]; then
        _failure "$@"
    fi
}

