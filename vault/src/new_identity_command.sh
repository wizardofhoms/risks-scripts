
# Base identity parameters
name="${args[name]}"
email="${args[email]}"
expiry="${args[expiry_date]}"

# Base filesystem parameters
PENDRIVE="${args[backup_device]}"
IDENTITY="${name// /_}"

_message "risks  " "Starting new identity generation process"

# Generate a passphrase for this identity. Only one argument 
# given will make spectre to prompt user for a master password. 
# This passphrase is used for encrypting all file/directory names,
# as well as fscrypt encryption.
passphrase=$(get_passphrase "${IDENTITY}" master)

_message "RAMdisk" "Setting up RAMDisk and GPG backend"
init_gpg

# Generate GPG keypairs with a different passphrase than the one
# we use for encrypting file/directory names and contents.
# This new key is also the one provided when using gpgpass command.
_message "gpg    " "Generating GPG keys"
gpg_passphrase=$(get_passphrase "${IDENTITY}" gpg "${passphrase}")
echo -n "${gpg_passphrase}" | xclip -loops 1 -selection clipboard
_run "gpg" gen_gpg_keys "${name}" "${email}" "${expiry}" "${gpg_passphrase}"

# Setup the identity graveyard directory with fscrypt protection
_message "graveyard" "Creating and setting encrypted identity directory"
new_graveyard "${IDENTITY}" "${passphrase}"

# At this point, we need access to the hush device, so make sure 
# it's mounted and that we have read-write permissions.
_message "hush" "Mounting hush device with read-write permissions"
risks_hush_mount_command
_run "hush" risks_hush_rw_command

# Then only, generate the coffin and copy it into the root graveyard
# (not the identity's graveyard subdirectory, because we need access to
# this file BEFORE anything else, since it contains the GPG keyring)
_message "coffin" "Creating and testing GPG coffin container"
gen_coffin "${IDENTITY}" "${passphrase}"

# Cleaning RAM disk, removing private keys from the keyring and test open/close 
_message "gpg   " "Cleaning and backing keyring privates"
cleanup_gpg_init "${IDENTITY}" "${email}" "${passphrase}"

_message "ssh   " "Generating SSH keypair and setting up related tools (multi-key ssh-agent script)" 
gen_ssh_keys "${IDENTITY}" "${email}" "${passphrase}"

_message "pass  " "Initializing password-store"
init_pass "${IDENTITY}" "${email}" "${passphrase}"

## Create a tomb to use for admin storage: 
# config files, etc, and set default key=values
_message "mgmt  " "Generating management tomb"
init_mgmt "${IDENTITY}" "${passphrase}"

## 8 - Create Signal tomb, set admin stuff and generate password
# for the enrypted data directory in the Signal VM.
_message "mgmt  " "Generating Signal messenger tomb"
_run "mgmt" new_tomb "${SIGNAL_TOMB_LABEL}" 20 "${IDENTITY}" "${passphrase}"
#
# ## 9 - Backup
_message "backup" "Backing up all identities' data and related partitions"
make_initial_identity_backup "${name}" "${PENDRIVE}" "${passphrase}" "${gpg_passphrase}"

## 10 - ALL DONE 
echo && _success "identity" "Identity generation complete." 
