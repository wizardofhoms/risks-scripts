
# Create a RAMDisk and setup the GPG directory in it, with configuration files
init_gpg()
{
    ## Creating
    _verbose 'Creating directory & setting permissions'
    rm -fR "${RAMDISK}"
    mkdir "${RAMDISK}"
    _run sudo mount -t tmpfs -o size=10m ramdisk "${RAMDISK}"
    _catch "Failed to mount tmp fs on ramdisk"
    sudo chown "${USER}" "${RAMDISK}" 
    _catch "Failed to set ownership to ${RAMDISK}"
    sudo chmod 0700 "${RAMDISK}" 
    _catch "Failed to change mod 0700 to ${RAMDISK}"

    ## Testing
    _verbose "Testing ramdisk read/write"
    _verbose "$(mount | grep ramdisk)"
    _verbose "Previous command should look like this: \n\n\
        ramdisk on /home/user/ramdisk type tmpfs (rw,relatime,size=10240k) \n\
        ramdisk on /rw/home/user/ramdisk type tmpfs (rw,relatime,size=10240k) \n"

    touch "${RAMDISK}/delme" && rm "${RAMDISK}/delme" 
    _catch "Failed to test write file ${1}"

    # Configuration files
    _verbose "Writing default GPG configuration file"
    cat >"${RAMDISK}/gpg.conf" <<EOF
# Avoid information leaked
no-emit-version
no-comments
export-options export-minimal

# Options for keys listing
keyid-format 0xlong
with-fingerprint
with-keygrip
with-subkey-fingerprint

# Displays the validity of the keys
list-options show-uid-validity
verify-options show-uid-validity

# Limits preferred algorithms
personal-cipher-preferences AES256
personal-digest-preferences SHA512
default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed

# Options for asymmetric encryption
cipher-algo AES256
digest-algo SHA512
cert-digest-algo SHA512
compress-algo ZLIB
disable-cipher-algo 3DES
weak-digest SHA1

# Options for symmetric encryption
s2k-cipher-algo AES256
s2k-digest-algo SHA512
s2k-mode 3
s2k-count 65011712
EOF
}

# Create key pairs for a given identity, based on a premade batch file
gen_gpg_keys()
{
    local name="$1"
    local email="$2"
    local expiry="$3"
    local passphrase="$4"

    local expiry_date fingerprint

    # Output the identity batch file with values
    _verbose "Writing GPG batch file to ramdisk"
    cat >"${RAMDISK}/primary_key_unattended" <<EOF
%echo Generating EDDSA key (Ed25519 curve)
Key-Type: eddsa 
Key-Curve: Ed25519 
Key-Usage: sign
Key-Length: 4096
Name-Real: ${name} 
Name-Email: ${email} 
Expire-Date: 0
Passphrase: ${passphrase} 
%commit
%echo done
EOF

    # Generate key and get rid of batch file
    _verbose "Generating primary key from batch file"
    _run gpg --batch --gen-key "${RAMDISK}/primary_key_unattended" 
    _catch "Failed to generate keys from batch file"
    _verbose "Deleting batch file"
    _run wipe -f "${RAMDISK}/primary_key_unattended" 
    _catch "Failed to wipe batch file: contains the identity passphrase"

    ## 2 - Subjeys creation 
    expiry_date="$(date +"%Y-%m-%d" --date="${expiry}")" 
    fingerprint=$(gpg -K "${email}" | grep fingerprint | head -n 1 | cut -d= -f2 | sed 's/ //g')
    _message "Fingerprint: ${fingerprint}"

    local gpg_base_cmd=(gpg --pinentry-mode loopback --batch --no-tty --yes --passphrase-fd 0 --quick-add-key "${fingerprint}")

    _verbose "Generating encryption subkey-pair"
    echo "$passphrase" | "${gpg_base_cmd[@]}" cv25519 encr "${expiry_date}" &> /dev/null
    _catch "Failed to generate encryption subkey-pair"

    _verbose "Generating signature subkey-pair"
    echo "$passphrase" | "${gpg_base_cmd[@]}" ed25519 sign "${expiry_date}" &> /dev/null
    _catch "Failed to generate signature subkey-pair"

    _verbose "Generating authentication subkey-pair"
    echo "$passphrase" | "${gpg_base_cmd[@]}" ed25519 auth "${expiry_date}" &> /dev/null
    _catch "subkeys" "Failed to generate authentication subkey-pair. Continuing still"

    _verbose "Directory structure:"
    _verbose "$(tree "${RAMDISK}")"
}

# A rather complete function performing several important, but quite unrelated, tasks:
# - Moves the GPG keyring of an identity into its coffin
# - Checks visually that files are where expected (if verbose flag set)
# - Removes the private keys from the keyring that is to be used daily
cleanup_gpg_init()
{
    local IDENTITY="$1"
    local email="$2"
    local pass="$3"

    local TMP_FILENAME TMP coffin_name

    # Filenames
    TMP_FILENAME=$(_encrypt_filename "${IDENTITY}" "${IDENTITY}-gpg" "$pass")
    TMP="/tmp/${TMP_FILENAME}"
    coffin_name=$(_encrypt_filename "${IDENTITY}" "coffin-${IDENTITY}-gpg" "$pass")

    # Making tmp directory
    _verbose "Creating temp directory and mounting coffin"
    mkdir "${TMP}"
    sudo mount /dev/mapper/"${coffin_name}" "${TMP}" 
    _catch "Failed to mount coffin partition on ${TMP}"       
    sudo chown "${USER}" "${TMP}"
    _verbose "Testing coffin filesystem"
    _verbose "$(mount | grep "${TMP_FILENAME}")"

    ## Moving GPG data into the coffin, and closing again
    _verbose "Copying GPG files in coffin"
    cp -fR "${RAMDISK}"/* "${TMP}" || _warning "Failed to copy one or more files into coffin"
    _verbose "Setting GPG files immutable"
    sudo chattr +i "${TMP}"/private-keys-v1.d/*
    _verbose "Closing coffin"
    sudo chattr +i "${TMP}"/openpgp-revocs.d/*
    sudo umount "${TMP}" || _warning "Failed to unmount tmp directory ${TMP}"
    sudo cryptsetup close /dev/mapper/"${coffin_name}" 
    _catch "Failed to close LUKS filesystem for identity"

    # Clearing RAMDisk
    _verbose "Wiping and unmounting ramdisk"
    _run sudo wipe -rf "${RAMDISK}"/*
    _catch "Failed to wipe ${RAMDISK} directory"
    sudo umount -l "${RAMDISK}" || _warning "Failed to unmount ramdisk ${RAMDISK}"

    ## 5 - Final checks 
    _verbose "Checking directory contents"
    _verbose "$(tree "${HUSH_DIR}" "${GRAVEYARD}")"
    _verbose "Should look like this:           \n\n \
/home/user/.hush                                    \n    \
    ├── fjdri3kff2i4rjkFA (joe-gpg.key)             \n    \
/home/user/.graveyard                               \n    \
    ├── fejk38RjhfEf13 (joe-gpg.coffin) \n"

    _verbose "Test opening and closing coffin for ${IDENTITY}"
    close_coffin "${IDENTITY}" "${pass}"
    open_coffin "${IDENTITY}" "${pass}"

    ## 6 - Removing GPG private keys 
    _verbose "Removing GPG private keys"

    local TOMB_SIZE KEYGRIP fingerprint

    TOMB_SIZE=15
    fingerprint=$(gpg -K "${email}" | grep fingerprint | head -n 1 | cut -d= -f2 | sed 's/ //g')

    # Creating tomb file for private keys and moving them
    _verbose "Creating tomb file for identity ${IDENTITY}"
    _run new_tomb "${GPG_TOMB_LABEL}" ${TOMB_SIZE} "${IDENTITY}" "$pass"
    _verbose "Opening tomb file"
    _run open_tomb "${GPG_TOMB_LABEL}" "${IDENTITY}" "${pass}"

    KEYGRIP="$(gpg -K | grep Keygrip | head -n 1 | cut -d= -f 2 | sed 's/ //g').key"
    _verbose "Keygrip: ${KEYGRIP}"

    _verbose "Copying private data to tomb"
    _verbose "Private keys"
    cp "${RAMDISK}"/private-keys-v1.d/"${KEYGRIP}" "${HOME}"/.tomb/"${GPG_TOMB_LABEL}"/
    _verbose "Revocation certificates"
    cp "${RAMDISK}"/openpgp-revocs.d/"${fingerprint}".rev "${HOME}"/.tomb/"${GPG_TOMB_LABEL}"/

    # Deleting keys from keyring
    _verbose "Wiping corresponding files in GPG keyring"
    sudo chattr -i "${RAMDISK}"/private-keys-v1.d/"${KEYGRIP}" 
    _run wipe -rf "${RAMDISK}"/private-keys-v1.d/"${KEYGRIP}" \
        || _warning "Failed to delete master private key from keyring !"
    sudo chattr -i "${RAMDISK}"/openpgp-revocs.d/"${fingerprint}".rev
    _run wipe -rf "${RAMDISK}"/openpgp-revocs.d/"${fingerprint}".rev \
        || _warning "Failed to delete master key revocation from keyring !"

    # Verbose checks
    _verbose "Printing GPG keyring. Should have 'sec#' instead of 'pub'"
    _verbose "$(gpg -K)"
    _verbose "Closing GPG tomb file"
    _run close_tomb "${GPG_TOMB_LABEL}" "${IDENTITY}" "${pass}"
}
