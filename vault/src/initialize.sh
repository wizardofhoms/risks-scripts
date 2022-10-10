
# Connected terminal
typeset -H _TTY
GPG_TTY=$(tty)  # Needed for GPG operations
export GPG_TTY

# Remove verbose errors when * don't yield any match in ZSH
setopt +o nomatch

# The generated script makes use of BASH_REMATCH, set compat for ZSH
setopt BASH_REMATCH

# Default filesystem settings from configuration file ----------------------------------------------
typeset -gr SDCARD_ENC_PART="$(config_get SDCARD_ENC_PART)"
typeset -gr SDCARD_ENC_PART_MAPPER="$(config_get SDCARD_ENC_PART_MAPPER)"
typeset -gr SDCARD_QUIET="$(config_get SDCARD_QUIET)"
typeset -gr BACKUP_MAPPER="$(config_get BACKUP_MAPPER)"
typeset -gr HUSH_DIR="$(config_get HUSH_DIR)"
typeset -gr GRAVEYARD="$(config_get GRAVEYARD)"

# Default tombs and corresponding mount points (CONSTANTS) .........................................
typeset -gr GPG_TOMB_LABEL="GPG"          # Stores an identity GPG private keys. Seldom opened
typeset -gr SSH_TOMB_LABEL="ssh"          # Stores SSH keypairs
typeset -gr MGMT_TOMB_LABEL="mgmt"        # Holds the key-value store, and anything the user wants.
typeset -gr PASS_TOMB_LABEL="pass"        # Holds the password store data
typeset -gr SIGNAL_TOMB_LABEL="signal"    # Holds data for Signal messenger (contacts, keys, configs, etc)

# Other default security-related default directories/names .........................................
typeset -gr RAMDISK="${HOME}/.gnupg"      # Actually not a tomb mount point: used by coffin

typeset -gr DEFAULT_KV_USER_DIR="$HOME/.tomb/mgmt/db/"   # Path to key=value store within mgmnt tomb 
typeset -gr RISKS_SCRIPTS_INSTALL_PATH="${HUSH_DIR}/.risks-scripts" # Path to risks bin in the hush
typeset -gr BACKUP_MOUNT_DIR="/tmp/pendrive"

typeset -gr FILE_ENCRYPTION="file_encryption_key" # Simply used as site name in spectre call.

typeset -rg RISKS_DIR="${HOME}/.risks"                         # Directory where risk stores its state
typeset -rg RISKS_IDENTITY_FILE="${RISK_DIR}/.identity"        # Currently unlocked identity stored in file

# Sensitive & and recurring variables used by program ..............................................
typeset -gH IDENTITY
typeset -gH FILE_ENCRYPTION_KEY
typeset -gH GPG_PASS

# Variables potentially overrode by user in their shell/rc .........................................
typeset -gH GPGPASS_TIMEOUT=45            # Can be modified with --timeout flag on gpgpass command

# Password-store
export PASSWORD_STORE_ENABLE_EXTENSIONS=true
export PASSWORD_STORE_GENERATED_LENGTH=20


#----------------------------#
## Checks ##

# Don't run as root
if [[ $EUID -eq 0 ]]; then
   echo "This script must be run as user"
   exit 2
fi

# Use colors unless told not to
{ ! option_is_set --no-color } && { autoload -Uz colors && colors }
