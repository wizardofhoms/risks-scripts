
# Global variables to be set in this root function
typeset -g IDENTITY EMAIL MASTER_PASS GPG_PASS

# Base identity parameters, set globally.
name="${args[name]}"
expiry="${args[expiry_date]}"

IDENTITY="${name// /_}"
EMAIL="${args[email]}"

# Base filesystem parameters
local pendrive="${args[backup_device]}"

# Start work =================================================================

_in_section 'risks' 6
_message "Starting new identity generation process"
_warning "Do not unplug hush and backup devices during the process"

# Generate a passphrase for this identity. Only one argument 
# given will make spectre to prompt user for a master password. 
# This passphrase is used for encrypting all file/directory names,
# as well as fscrypt encryption.
MASTER_PASS=$(get_passphrase "$IDENTITY")

_in_section 'gpg' && _message "Setting up RAMDisk and GPG backend"
init_gpg

# Generate GPG keypairs with a different passphrase than the one
# we use for encrypting file/directory names and contents.
# This new key is also the one provided when using gpgpass command.
_message "Generating GPG keys"

GPG_PASS=$(get_passphrase "$IDENTITY" "$GPG_TOMB_LABEL")
echo -n "$GPG_PASS" | xclip -loops 1 -selection clipboard
_warning "GPG passphrase copied to clipboard with one-time use only"

_run gen_gpg_keys "$name" "$EMAIL" "$expiry" "$GPG_PASS"

# Setup the identity graveyard directory with fscrypt protection
_in_section 'coffin' && _message "Creating and setting encrypted identity directory"
new_graveyard "$IDENTITY"

# At this point, we need access to the hush device, so make sure 
# it's mounted and that we have read-write permissions.
_in_section 'hush' && _message "Mounting hush device with read-write permissions"
risks_hush_mount_command
_run risks_hush_rw_command

# Then only, generate the coffin and copy it into the root graveyard
# (not the identity's graveyard subdirectory, because we need access to
# this file BEFORE anything else, since it contains the GPG keyring)
_in_section 'coffin' && _message "Creating and testing GPG coffin container"
gen_coffin "$IDENTITY"

# Cleaning RAM disk, removing private keys from the keyring and test open/close 
_in_section 'gpg' && _message "Cleaning and backing keyring privates"
cleanup_gpg_init "$IDENTITY" "$EMAIL"

_in_section 'ssh' && _message "Generating SSH keypair and multi-key ssh-agent script" 
gen_ssh_keys "$IDENTITY" "$EMAIL"

_in_section 'pass' && _message "Initializing password-store"
init_pass "$IDENTITY" "$EMAIL"

## Create a tomb to use for admin storage: 
# config files, etc, and set default key=values
_in_section 'mgmt' && _message "Generating management tomb"
init_mgmt "$IDENTITY"

## 8 - Create Signal tomb, set admin stuff and generate password
# for the enrypted data directory in the Signal VM.
_in_section 'signal' && _message "Generating Signal messenger tomb"
_run new_tomb "$SIGNAL_TOMB_LABEL" 20 "$IDENTITY"
#
# ## 9 - Backup
_in_section 'backup' && _message "Backing up all identities' data and related partitions"
make_initial_identity_backup "$IDENTITY" "$pendrive"

## 10 - ALL DONE 
echo && _success "risks" "Identity generation complete." 
