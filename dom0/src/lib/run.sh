
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

# run a command in a qube
# $1 - Qube name
# $@ - Command string to run
_qrun () {
    local vm="$1"
    shift
    local command="$*"

    # Prepare the full command
    local xterm_command='zsh -c "'"$command"'"'
    local full_command=(qvm-run --pass-io "$vm" xterm -e "$xterm_command")

    _verbose "Running command: ${full_command[*]}"
    
    # Split io like in _run, and store the return value
    # Note that we don't double quote the $full_command variable.
    {
        IFS=$'\n' read -r -d '' COMMAND_STDERR;
        IFS=$'\n' read -r -d '' COMMAND_STDOUT;
        (IFS=$'\n' read -r -d '' _ERRNO_; exit "${_ERRNO_}");
    } < <((printf '\0%s\0%d\0' "$(${full_command[@]})" "${?}" 1>&2) 2>&1)

    local ret="$?"

    # Output the command's result depending on the verbose mode
    # and if the command ran successfully like in _run also.
    if [[ $ret -eq 0 ]] && is_verbose_set ; then
        if [[ -n "$COMMAND_STDOUT" ]]; then
            _verbose "$COMMAND_STDOUT"
        fi
    fi

    return $ret
}

_qvrun () {
    local vm="$1"
    shift
    local full_command="$*"

    _verbose "Running command: ${full_command[*]}"

    # Run the command raw, so that we get the output as it is.
    qvm-run --pass-io "$vm" "${full_command[*]}"
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


#assertRunning [vm] [start]
#Assert that the given VM is running. Will unpause paused VMs and may start shut down VMs.
#[vm]: VM for which to make sure it's running.
#[start]: If it's not running and not paused, start it (default: 0/true). If set to 1, this function will return a non-zero exit code.
#returns: A non-zero exit code, if it's not running and/or we failed to start the VM.
function assertRunning {
    local vm="$1"
    local start="${2:-0}"

    #make sure the VM is unpaused
    if qvm-check --paused "$vm" &> /dev/null ; then
        qvm-unpause "$vm" &> /dev/null || return 1
    else
        if [ $start -eq 0 ] ; then
            qvm-start --skip-if-running "$vm" &> /dev/null || return 1
        else
            #we don't attempt to start
            return 2
        fi
    fi

    return 0
}

# start_vm [vm 1] ... [vm n]
#Start the given VMs without executing any command.
function start_vm {
    local ret=0

    local vm=
    declare -A pids=() #VM --> pid
    for vm in "$@" ; do
        [[ "$vm" == "dom0" ]] && continue
        _verbose "Starting: $vm"
        assertRunning "$vm" &
        pids["$vm"]=$!
    done

    local failed=""
    local ret=
    for vm in "${(@k)pids}" ; do
        wait "${pids["$vm"]}"
        ret=$?
        [ $ret -ne 0 ] && failed="$failed"$'\n'"$vm ($ret)"
    done

    [ -z "$failed" ] || _verbose "Starting the following VMs failed: $failed"

    #set exit code
    [ -z "$failed" ]
}

# shutdown_vm [vm 1] ... [vm n]
#Shut the given VMs down.
function shutdown_vm {
    local ret=0

    if [ $# -gt 0 ] ; then
        #make sure the VMs are unpaused
        #cf. https://github.com/QubesOS/qubes-issues/issues/5967
        local vm=
        for vm in "$@" ; do
            qvm-unpause "$vm" &> /dev/null
        done

        _verbose "Shutting down: $*"
        qvm-shutdown --wait "$@"
        ret=$?
    fi

    return $ret
}
