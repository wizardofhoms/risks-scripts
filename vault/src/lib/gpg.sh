
# Create a RAMDisk and setup the GPG directory in it, with configuration files
init_gpg()
{
    ## Creating
    _verbose 'ramdisk' 'Creating directory & setting permissions'
    rm -fR "${RAMDISK}"
    mkdir "${RAMDISK}"
    _run 'ramdisk' sudo mount -t tmpfs -o size=10m ramdisk "${RAMDISK}"
    _catch 'ramdisk' "Failed to mount tmp fs on ramdisk"
    sudo chown "${USER}" "${RAMDISK}" 
    _catch 'ramdisk' "Failed to set ownership to ${RAMDISK}"
    sudo chmod 0700 "${RAMDISK}" 
    _catch 'ramdisk' "Failed to change mod 0700 to ${RAMDISK}"

    ## Testing
    _verbose "ramdisk" "Testing ramdisk read/write"
    _verbose "ramdisk" "$(mount | grep ramdisk)"
    _verbose "ramdisk" "Previous command should look like this: \n\n\
        ramdisk on /home/user/ramdisk type tmpfs (rw,relatime,size=10240k) \n\
        ramdisk on /rw/home/user/ramdisk type tmpfs (rw,relatime,size=10240k) \n"

    touch "${RAMDISK}/delme" && rm "${RAMDISK}/delme" 
    _catch "ramdisk" "Failed to test write file ${1}"

    # Configuration files
    _verbose "gpg" "Writing default GPG configuration file"
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
    _verbose "gpg" "Writing GPG batch file to ramdisk"
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
    _verbose "gpg" "Generating primary key from batch file"
    _run 'gpg' gpg --batch --gen-key "${RAMDISK}/primary_key_unattended" 
    _catch 'gpg' "Failed to generate keys from batch file"
    _verbose "gpg" "Deleting batch file"
    _run 'gpg' wipe -f "${RAMDISK}/primary_key_unattended" 
    _catch 'gpg' "Failed to wipe batch file: contains the identity passphrase"

    ## 2 - Subjeys creation 
    expiry_date="$(date +"%Y-%m-%d" --date="${expiry}")" 
    fingerprint=$(gpg -K "${email}" | grep fingerprint | head -n 1 | cut -d= -f2 | sed 's/ //g')
    _message "gpg" "Fingerprint: ${fingerprint}"

    local gpg_base_cmd=(gpg --pinentry-mode loopback --batch --no-tty --yes --passphrase-fd 0 --quick-add-key "${fingerprint}")

    _verbose "gpg" "Generating encryption subkey-pair"
    echo "$passphrase" | "${gpg_base_cmd[@]}" cv25519 encr "${expiry_date}" &> /dev/null
    _catch 'gpg' "Failed to generate encryption subkey-pair"

    _verbose "gpg" "Generating signature subkey-pair"
    echo "$passphrase" | "${gpg_base_cmd[@]}" ed25519 sign "${expiry_date}" &> /dev/null
    _catch 'gpg' "Failed to generate signature subkey-pair"

    _verbose "gpg" "Generating authentication subkey-pair"
    echo "$passphrase" | "${gpg_base_cmd[@]}" ed25519 auth "${expiry_date}" &> /dev/null
    _catch 'gpg' "subkeys" "Failed to generate authentication subkey-pair. Continuing still"

    _verbose "gpg" "Directory structure:"
    _verbose "gpg" "$(tree "${RAMDISK}")"
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
    _verbose "coffin" "Creating temp directory and mounting coffin"
    mkdir "${TMP}"
    sudo mount /dev/mapper/"${coffin_name}" "${TMP}" 
    _catch "coffin" "Failed to mount coffin partition on ${TMP}"       
    sudo chown "${USER}" "${TMP}"
    _verbose "coffin" "Testing coffin filesystem"
    _verbose "coffin" "$(mount | grep "${TMP_FILENAME}")"

    ## Moving GPG data into the coffin, and closing again
    _verbose "coffin" "Copying GPG files in coffin"
    cp -fR "${RAMDISK}"/* "${TMP}" || _warning "coffin" "Failed to copy one or more files into coffin"
    _verbose "coffin" "Setting GPG files immutable"
    sudo chattr +i "${TMP}"/private-keys-v1.d/*
    _verbose "coffin" "Closing coffin"
    sudo chattr +i "${TMP}"/openpgp-revocs.d/*
    sudo umount "${TMP}" || _warning "coffin" "Failed to unmount tmp directory ${TMP}"
    sudo cryptsetup close /dev/mapper/"${coffin_name}" 
    _catch "coffin" "Failed to close LUKS filesystem for identity"

    # Clearing RAMDisk
    _verbose "ramdisk" "Wiping and unmounting ramdisk"
    _run "ramdisk" sudo wipe -rf "${RAMDISK}"/*
    _catch "ramdisk" "Failed to wipe ${RAMDISK} directory"
    sudo umount -l "${RAMDISK}" || _warning "ramdisk" "Failed to unmount ramdisk ${RAMDISK}"

    ## 5 - Final checks 
    _verbose "coffin" "Checking directory contents"
    _verbose "coffin" "$(tree "${HUSH_DIR}" "${GRAVEYARD}")"
    _verbose "coffin" "Should look like this:           \n\n \
/home/user/.hush                                    \n    \
    ├── fjdri3kff2i4rjkFA (joe-gpg.key)             \n    \
/home/user/.graveyard                               \n    \
    ├── fejk38RjhfEf13 (joe-gpg.coffin) \n"

    _verbose "coffin" "Test opening and closing coffin for ${IDENTITY}"
    close_coffin "${IDENTITY}" "${pass}"
    open_coffin "${IDENTITY}" "${pass}"

    ## 6 - Removing GPG private keys 
    _verbose "gpg" "Removing GPG private keys"

    local TOMB_SIZE KEYGRIP fingerprint

    TOMB_SIZE=15
    fingerprint=$(gpg -K "${email}" | grep fingerprint | head -n 1 | cut -d= -f2 | sed 's/ //g')

    # Creating tomb file for private keys and moving them
    _verbose "gpg" "Creating tomb file for identity ${IDENTITY}"
    _run "gpg" new_tomb "${GPG_TOMB_LABEL}" ${TOMB_SIZE} "${IDENTITY}" "$pass"
    _verbose "gpg" "Opening tomb file"
    _run "gpg" open_tomb "${GPG_TOMB_LABEL}" "${IDENTITY}" "${pass}"

    KEYGRIP="$(gpg -K | grep Keygrip | head -n 1 | cut -d= -f 2 | sed 's/ //g').key"
    _verbose "gpg" "Keygrip: ${KEYGRIP}"

    _verbose "gpg" "Copying private data to tomb"
    _verbose "gpg" "Private keys"
    cp "${RAMDISK}"/private-keys-v1.d/"${KEYGRIP}" "${HOME}"/.tomb/"${GPG_TOMB_LABEL}"/
    _verbose "gpg" "Revocation certificates"
    cp "${RAMDISK}"/openpgp-revocs.d/"${fingerprint}".rev "${HOME}"/.tomb/"${GPG_TOMB_LABEL}"/

    # Deleting keys from keyring
    _verbose "gpg" "Wiping corresponding files in GPG keyring"
    sudo chattr -i "${RAMDISK}"/private-keys-v1.d/"${KEYGRIP}" 
    _run 'gpg' wipe -rf "${RAMDISK}"/private-keys-v1.d/"${KEYGRIP}" \
        || _warning "gpg" "Failed to delete master private key from keyring !"
    sudo chattr -i "${RAMDISK}"/openpgp-revocs.d/"${fingerprint}".rev
    _run 'gpg' wipe -rf "${RAMDISK}"/openpgp-revocs.d/"${fingerprint}".rev \
        || _warning "gpg" "Failed to delete master key revocation from keyring !"

    # Verbose checks
    _verbose "gpg" "Printing GPG keyring. Should have 'sec#' instead of 'pub'"
    _verbose "$(gpg -K)"
    _verbose "gpg" "Closing GPG tomb file"
    _run "gpg" close_tomb "${GPG_TOMB_LABEL}" "${IDENTITY}" "${pass}"
}
