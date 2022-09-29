
# Base identity parameters
name="${args[name]}"
email="${args[email]}"
expiry="${args[expiry_date]}"

# Base filesystem parameters
PENDRIVE="${args[backup_device]}"
IDENTITY="${name// /_}"

# Generate a passphrase for this identity. Only one argument 
# given will make spectre to prompt user for a master password. 
passphrase=$(get_passphrase "${IDENTITY}" master)

_message "RAMdisk" "Setting up RAMDisk and GPG backend"
init_gpg

_message "GPG" "Generating GPG keys"
gen_gpg_keys "${name}" "${email}" "${expiry}" "${passphrase}"

# Setup the identity graveyard directory with fscrypt protection
_message "graveyard" "Creating and setting encrypted identity directory"
new_graveyard "${IDENTITY}" "${passphrase}"

# Then only, generate the coffin and copy it into the root graveyard
# (not the identity's graveyard subdirectory, because we need access to
# this file BEFORE anything else, since it contains the GPG keyring)
_message "coffin" "Generating and testing GPG coffin container"
gen_coffin "${IDENTITY}" "${passphrase}"

# Cleaning RAM disk, removing private keys from the keyring and test open/close 
_message "GPG" "Cleaning and backing keyring privates"
cleanup_gpg_init "${IDENTITY}" "${email}" "${passphrase}"

_message "SSH" "Generating SSH keypair and setting up related tools (multi-key ssh-agent script)" 
gen_ssh_keys "${IDENTITY}" "${email}" "${passphrase}"

_message "pass" "Initializing password-store"
init_pass "${IDENTITY}" "${email}" "${passphrase}"

## Create a tomb to use for admin storage: 
# config files, etc, and set default key=values
_message "mgmt" "Generating management tomb"
init_mgmt "${IDENTITY}" "${passphrase}"

## 8 - Create Signal tomb, set admin stuff and generate password
# for the enrypted data directory in the Signal VM.
_message "mgmt" "Generating Signal messenger tomb"
new_tomb "${SIGNAL_TOMB_LABEL}" 20 "${IDENTITY}" "${passphrase}"
#
# ## 9 - Backup
_message "backup" "Backing up all identities' data and related partitions"
make_initial_identity_backup "${name}" "${email}" "${PENDRIVE}" "${passphrase}"

## 10 - ALL DONE 
echo && _success "identity" "Identity generation complete." 
