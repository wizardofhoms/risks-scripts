
#----------------------------#
## DEFAULTS ##

typeset -H _TTY

# Remove verbose errors when * don't yield any match in ZSH
setopt +o nomatch


#----------------------------#
## Variables ## 

RAMDISK="${HOME}/.gnupg"

GPG_TOMB_LABEL="GPG"          # Stores an identity GPG private keys. Seldom opened
SSH_TOMB_LABEL="ssh"          # Stores SSH keypairs
MGMT_TOMB_LABEL="mgmt"        # Holds the key-value store, and anything the user wants.
PASS_TOMB_LABEL="pass"        # Holds the password store data
SIGNAL_TOMB_LABEL="signal"    # Holds data for Signal messenger (contacts, keys, configs, etc)

GPGPASS_TIMEOUT=45            # Can be modified with --timeout flag on gpgpass command

# Default directory where to save key=values
default_kv_user_dir="$HOME/.tomb/mgmt/db/" 

# The identity used by RISKS, set when one of the identities 
# is unlocked, and reset when this identity is closed.
RISKS_IDENTITY_FILE="${HOME}/.identity"

# Password-store
export PASSWORD_STORE_ENABLE_EXTENSIONS=true
export PASSWORD_STORE_GENERATED_LENGTH=12

# Path where risks scripts are stored on the hush
RISKS_SCRIPTS_INSTALL_PATH="${HUSH_DIR}/.risks-scripts"

# Needed for GPG operations
GPG_TTY=$(tty)
export GPG_TTY


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
