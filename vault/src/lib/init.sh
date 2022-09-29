
# This file contains additional identity initialization functions.

## Creates a tomb storing the password-store and sets the latter up 
init_pass () 
{
    local IDENTITY="${1}"       
    local email="${2}"
    local passphrase="${3}"

    _verbose "pass" "Creating tomb file for pass"
    new_tomb "${PASS_TOMB_LABEL}" 20 "${IDENTITY}" "$passphrase"
    _verbose "pass" "Opening password store"
    open_tomb "${PASS_TOMB_LABEL}" "${IDENTITY}" "$passphrase"
    _verbose "pass" "Initializating password store with recipient ${email}"
    pass init "${email}"
    _verbose "pass" "Closing pass tomb file"
    close_tomb "${PASS_TOMB_LABEL}" "${IDENTITY}" "$passphrase"
}

# Creates a default management tomb in which, between others, the key=value store is being kept.
init_mgmt ()
{
    local IDENTITY="${1}"       
    local passphrase="${2}"

    _verbose "mgmt" "Creating tomb file for management (key=value store, etc)"
    new_tomb "${MGMT_TOMB_LABEL}" 10 "${IDENTITY}" "$passphrase"
    _verbose "mgmt" "Opening management tomb"
    open_tomb "${MGMT_TOMB_LABEL}" "${IDENTITY}" "$passphrase"
    _verbose "mgmt" "Closing management tomb"
    close_tomb "${MGMT_TOMB_LABEL}" "${IDENTITY}" "$passphrase"
}

# store_risks_scripts copies the various vault risks scripts in a special directory in the
# hush partition, along with a small installation scriptlet, so that upon mounting the hush
# somewhere else, the user can quickly install and use the risks on the new machine.
store_risks_scripts ()
{
    # local prg_path="$0"

    _message "scripts" "Copying risks scripts onto the hush partition"
    mkdir -p "${RISKS_SCRIPTS_INSTALL_PATH}"
    sudo cp "$(which risks)" "${RISKS_SCRIPTS_INSTALL_PATH}"
    sudo cp /usr/local/share/zsh/site-functions/_risks "${RISKS_SCRIPTS_INSTALL_PATH}"

    cat >"${RISKS_SCRIPTS_INSTALL_PATH}/install" <<'EOF'
#!/usr/bin/env zsh

local INSTALL_SCRIPT_DIR="${0:a:h}"
local INSTALL_SCRIPT_PATH="$0"
local BINARY_INSTALL_DIR="${HOME}/.local/bin"
local COMPLETIONS_INSTALL_DIR="${HOME}/.local/share/zsh/site-functions"

## Binary -------------
#
echo "Installing risks script in ${BINARY_INSTALL_DIR}"
if [[ ! -d "${BINARY_INSTALL_DIR}" ]]; then
    mkdir -p "${BINARY_INSTALL_DIR}"
fi
cp "${INSTALL_SCRIPT_PATH}" "${BINARY_INSTALL_DIR}"

## Completions --------
#
echo "Installing risks completions in ${COMPLETIONS_INSTALL_DIR}"
if [[ ! -d "${COMPLETIONS_INSTALL_DIR}" ]]; then
    echo "Completions directory does not exist. Creating it."
    echo "You should add it to ${FPATH} and reload your shell"
    mkdir -p "${COMPLETIONS_INSTALL_DIR}"
fi
cp "${INSTALL_SCRIPT_DIR}/_risks" "${COMPLETIONS_INSTALL_DIR}"

echo "Done installing risks scripts."
EOF
}

# make_initial_identity_backup is used at the end of an identity creation process:
# when secret keys are still available in the keyring, as well as some other files,
# we export them, along with a full backup of the hush img.
make_initial_identity_backup () 
{
    local name="$1"
    local email="$2"
    local PENDRIVE="$3" 
    local passphrase="${4}"

    local IDENTITY="${name// /_}"       # Used for files
    local MAPPER="pendev"
    local MOUNT_POINT="/tmp/pendrive"

    local fingerprint BCKDIR

    # Identity and passwords
    _verbose "backup" "Opening identity ${IDENTITY}"
    open_coffin "${IDENTITY}" "${passphrase}"
    fingerprint=$(gpg -K "${email}" | grep fingerprint | head -n 1 | cut -d= -f2 | sed 's/ //g')
    _verbose "backup" "Primary key fingerprint: ${fingerprint}"

    # GPG & Coffin Backup
    _verbose "backup" "Backing GPG keyring & coffin"

    if [[ ! -d ${MOUNT_POINT} ]]; then
            _verbose "backup" "Creating mount point directory"
            mkdir ${MOUNT_POINT} &> /dev/null
            _verbose "backup" "Changing directory owner to ${USER}"
            sudo chown "${USER}" ${MOUNT_POINT}
    fi

    _verbose "backup" "Opening LUKS pendrive"
    sudo cryptsetup open --type luks "${PENDRIVE}" ${MAPPER}
    _catch "backup" "Failed to open LUKS pendrive. Aborting"
    sudo mount /dev/mapper/${MAPPER} ${MOUNT_POINT}

    local BCKDIR="${MOUNT_POINT}/gpg/${IDENTITY}"
    if [[ ! -d ${BCKDIR} ]]; then
            _verbose "backup" "Creating backup directory for ${IDENTITY}"
            mkdir -p "${BCKDIR}"
    fi

    # GPG backup
    _verbose "backup" "Opening identity ${IDENTITY}"
    _verbose "backup" "Backing up gpg -K output on drive (as gpg-k_output.txt)"
    gpg -K > "${BCKDIR}"/gpg-k_output.txt
    gpg_base_cmd=(gpg --pinentry-mode loopback --batch --no-tty --yes --passphrase-fd 0)

    # Primary key-pair backup
    _verbose "backup" "Backing up primary key-pair (armored)"
    _verbose "backup" "Private key"
    echo "${passphrase}" | "${gpg_base_cmd[@]}" --export-secret-keys \
        --armor "${fingerprint}" > "${BCKDIR}"/private-primary-keypair.arm.key
    _verbose "backup" "Public key"
    gpg --export --armor "${fingerprint}" > "${BCKDIR}"/public-primary-keypair.arm.key

    # Subkey-pairs backup
    _verbose "backup" "Backing up subkey-pairs (armored)"
    echo "${passphrase}" | "${gpg_base_cmd[@]}" --export-secret-subkeys \
        "${fingerprint}" > "${BCKDIR}"/private-subkeys.bin.key
    _verbose "backup" "Listing directory (should have 4 files for this identity)"
    _verbose "backup" "$(ls -l "${BCKDIR}")"

    # Unmount and close everything before the backup step
    _verbose "backup" "Closing identity ${IDENTITY}"
    close_coffin "${IDENTITY}" "${passphrase}"

    # This is redundant with the _full_backup function, but we need to have access to identity files
    # for setting/unsetting immutability, and testing we correctly backed them.
    #
    # Hush backup
    _verbose "backup" "Backing hush partition"
    _verbose "backup" "Unmounting hush partition"
    hush_umount_command
    _verbose "backup" "Backing up hush as .img to pendrive"
    if [[ -e ${MOUNT_POINT}/hush.img ]]; then
            sudo chattr -i ${MOUNT_POINT}/hush.img          # Otherwise we can't overwrite
    fi
    sudo dd if=/dev/hush of=${MOUNT_POINT}/hush.img status=progress bs=16M

    # Graveyard backup 
    _verbose "backup" "3) Backing tomb files"
    _verbose "backup (graveyard)" "Backing up graveyard to pendrive"
    if [[ ! -d ${MOUNT_POINT}/graveyard ]]; then
            _verbose "backup (graveyard)" "Creating graveyard directory on pendrive"
            mkdir ${MOUNT_POINT}/graveyard &> /dev/null
    fi
    _verbose "backup (graveyard)" "Copying graveyard files"
    sudo chattr -i ${MOUNT_POINT}/graveyard/* \
        || _verbose "backup" "No files in backup/graveyard for which to change immutability properties"
    cp -fR "${HOME}"/.graveyard/* ${MOUNT_POINT}/graveyard \
    _catch "backup" "Failed to copy graveyard files to backup medium"

    # Testing backup 
    _verbose "backup" "4) Testing backup"
    _verbose "backup" "Printing directory tree in backup pendrive"
    _verbose "backup" "$(tree ${MOUNT_POINT})"
    _verbose "backup" "Should have 4 files in gpg/${IDENTITY}/, hush.img and graveyard in root"
    _verbose "backup" "Making all backup files immutable"
    sudo chattr +i ${MOUNT_POINT}/graveyard/*
    sudo chattr +i ${MOUNT_POINT}/hush.img
    sudo chattr +i ${MOUNT_POINT}/gpg/"${IDENTITY}"/*

    _verbose "backup" "Unmounting backup pendrive"
    sudo umount ${MOUNT_POINT}
    _verbose "backup" "Closing LUKS filesystem"
    sudo cryptsetup close ${MAPPER}
}
