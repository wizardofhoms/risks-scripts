
# Connected terminal
typeset -H _TTY
GPG_TTY=$(tty)  # Needed for GPG operations
export GPG_TTY

# Remove verbose errors when * don't yield any match in ZSH
setopt +o nomatch


#----------------------------#
## Checks ##

# Don't run as root
if [[ $EUID -eq 0 ]]; then
   echo "This script must be run as user"
   exit 2
fi

# Use colors unless told not to
{ ! option_is_set --no-color } && { autoload -Uz colors && colors }
# Some options are only available during insecure mode
{ ! option_is_set --unsafe } && {
    for opt in --tomb-pwd --tomb-old-pwd; do
        { option_is_set $opt } && {
            exitv=127 _failure "You specified option ::1 option::, \
            which is DANGEROUS and should only be used for testing\n \
            If you really want so, add --unsafe" $opt }
    done
}
