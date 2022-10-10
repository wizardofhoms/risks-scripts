
local name identity expiry pendrive email

# Base identity parameters, set globally.
name="${args[name]}"
expiry="${args[expiry_date]}"

identity="${name// /_}"
email="${args[email]}"

# Backup is optional
pendrive="${args[--backup]}"

# Pre-run checks =============================================================

# No identity should be active, because some important mount points will be
# unaccessible or might risk ending in a dangling state.
if _identity_active ; then
    _failure "An identity seems to be active. Cannot safely create a new one."
fi

# Check the hush device is, if mounted, on a read-only state at this point.
# We fail if it's read-write, because we should assume another process is
# currently writing to it.
if is_hush_mounted && [[ -w "$HUSH_DIR" ]]; then
    _failure "Hush is currently mounted read-write. \n \
   Please ensure nothing is writing to it and set it to read-only first"
fi


# Start work =================================================================

_in_section 'risks' 6
_message "Starting new identity generation process"
_warning "Do not unplug hush and backup devices during the process"

# Use the identity name to set its file encryption key.
# This call propagates some of those essential variables 
# so that all functions can use them.
_set_identity "$identity"

# GPG 
#
_in_section 'gpg' && _message "Setting up RAMDisk and GPG backend"
init_gpg

# Generate GPG keypairs with a different passphrase than the one
# we use for encrypting file/directory names and contents.
_message "Generating GPG keys"

# This new key is also the one provided when using gpgpass command.
GPG_PASS=$(get_passphrase "$GPG_TOMB_LABEL")
echo -n "$GPG_PASS" | xclip -loops 1 -selection clipboard
_warning "GPG passphrase copied to clipboard with one-time use only"
_message -n "Copy it in the coming GPG prompt when creating builtin tombs\n"

_run gen_gpg_keys "$name" "$email" "$expiry"

# Setup the identity graveyard directory with fscrypt protection
_in_section 'coffin' && _message "Creating and setting encrypted identity directory"
new_graveyard

# At this point, we need access to the hush device, so make sure 
# it's mounted and that we have read-write permissions.
_in_section 'hush' && _message "Mounting hush device with read-write permissions"
risks_hush_mount_command
_run risks_hush_rw_command

# Then only, generate the coffin and copy it into the root graveyard
# (not the identity's graveyard subdirectory, because we need access to
# this file BEFORE anything else, since it contains the GPG keyring)
_in_section 'coffin' && _message "Creating and testing GPG coffin container"
gen_coffin

# Cleaning RAM disk, removing private keys from the keyring and test open/close 
_in_section 'gpg' && _message "Cleaning and backing keyring privates"
cleanup_gpg_init "$email"


## Builtin tombs
#
_in_section 'ssh' && _message "Generating SSH keypair and multi-key ssh-agent script" 
gen_ssh_keys "$email"

_in_section 'pass' && _message "Initializing password-store"
init_pass "$email"

## Create a tomb to use for admin storage: 
# config files, etc, and set default key=values
_in_section 'mgmt' && _message "Generating management tomb"
init_mgmt

## 8 - Create Signal tomb, set admin stuff and generate password
# for the enrypted data directory in the Signal VM.
_in_section 'signal' && _message "Generating Signal messenger tomb"
_run new_tomb "$SIGNAL_TOMB_LABEL" 20


## Backup
#
if [[ -n "$pendrive" ]]; then
    # Check the path to the backup drive is a LUKS device.
    # pendrive_error=$(validate_device "$pendrive")
    # if [[ -n $pendrive_error ]]; then 
    #     _failure "Device file $pendrive seems not to be a LUKS filesystem."
    # fi

    _in_section 'backup' && _message "Setting identity backup and making initial one"

    risks_backup_mount_command
    _catch "failed to decrypt and mount backup drive"

    # Some setup is needed for this identity to have access to its backup
    _verbose "Setting graveyard backup for this identity"
    _run setup_identity_backup
    _catch "Failed to setup identity backup graveyard"

    # And then actually back it up
    risks_backup_identity_command
    _catch "Failed to correctly backup data"

    risks_backup_umount_command
fi

## 10 - ALL DONE 
echo && _success "risks" "Identity generation complete." && echo
