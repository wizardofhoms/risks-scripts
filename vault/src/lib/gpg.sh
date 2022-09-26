
# Create a RAMDisk and setup the GPG directory in it, with configuration files
init_gpg()
{
    ## Creating
    _verbose 'ramdisk' 'Creating directory & setting permissions'
    rm -fR ${RAMDISK}
    mkdir ${RAMDISK}
    mount -t tmpfs -o size=10m ramdisk ${RAMDISK} || _failure "Failed to mount tmp fs on ramdisk"
    $s chown ${USER} ${RAMDISK} || _failure "Failed to set ownership to ${RAMDISK}"
    $s chmod 0700 ${RAMDISK} || _failure "Failed to change mod 0700 to ${RAMDISK}"

    ## Testing
    _message "ramdisk" "Testing"
    _verbose "$(mount | grep ramdisk)"
    _verbose "ramdisk" "Previous command should look like this: \n\n\
        ramdisk on /home/user/ramdisk type tmpfs (rw,relatime,size=10240k) \n\
        ramdisk on /rw/home/user/ramdisk type tmpfs (rw,relatime,size=10240k) \n"

    _verbose "ramdisk" "Testing creation/deletion of files"
    touch "${RAMDISK}/delme" && rm "${RAMDISK}/delme" || _failure "ramdisk" "Failed to test write file ${1}"

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

    # Output the identity batch file with values
    _verbose "gpg" "Writing GPG batch file to ramdisk"
    cat >${RAMDISK}/primary_key_unattended <<EOF
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
    gpg --batch --gen-key ${RAMDISK}/primary_key_unattended || _failure "Failed to generate keys from batch file"
    _verbose "gpg" "Deleting batch file"
    wipe -f ${RAMDISK}/primary_key_unattended || _failure "Failed to wipe batch file: contains the identity passphrase"
    _verbose "gpg" "Listing keys:"
    local fingerprint=$(gpg -K ${email} | grep fingerprint | head -n 1 | cut -d= -f2 | sed 's/ //g')
    _msg "gpg" "Fingerprint: ${fingerprint}"

    ## 2 - Subjeys creation 
    _verbose "gpg" "Generating encryption subkey-pair"
    local expiry_date="$(date +"%Y-%m-%d" --date="${expiry}")" 
    echo "$passphrase" | gpg --pinentry-mode loopback --batch --no-tty --yes --passphrase-fd 0 --quick-add-key ${fingerprint} cv25519 encr ${expiry_date} \
            || _failure "Failed to generate encryption subkey-pair"

    _verbose "gpg" "Generating signature subkey-pair"
    echo "$passphrase" | gpg --pinentry-mode loopback --batch --no-tty --yes --passphrase-fd 0 --quick-add-key ${fingerprint} ed25519 sign ${expiry_date} \
            || _failure "Failed to generate signature subkey-pair"

    _verbose "gpg" "Generating authentication subkey-pair"
    echo "$passphrase" | gpg --pinentry-mode loopback --batch --no-tty --yes --passphrase-fd 0 --quick-add-key ${fingerprint} ed25519 auth ${expiry_date} \
            || _warning "subkeys" "Failed to generate authentication subkey-pair. Continuing still"

    _verbose "gpg" "Directory structure:"
    verbose "gpg" "$(tree ${RAMDISK})"
}

# A rather complete function performing several important, but quite unrelated, tasks:
# - Moves the GPG keyring of an identity into its coffin
# - Checks visually that files are where expected 
# - Removes the private keys from the keyring that is used daily
cleanup_gpg_init()
{
    local IDENTITY="$1"
    local email="$2"
    local pass="$3"

    # Filenames
    local TMP_FILENAME=$(_encrypt_filename ${IDENTITY} "${IDENTITY}-gpg" "$pass")
    local TMP="/tmp/${TMP_FILENAME}"
    local coffin_name=$(_encrypt_filename ${IDENTITY} "coffin-${IDENTITY}-gpg" "$pass")

    # Making tmp directory
    _verbose "coffin" "Creating temp directory and mounting coffin"
    mkdir ${TMP}
    sudo mount /dev/mapper/${coffin_name} ${TMP} || _failure "coffin" "Failed to mount coffin partition on ${TMP}"       
    $s chown ${USER} ${TMP}
    _verbose "coffin" "Testing coffin filesystem"
    _verbose "$(mount | grep ${TMP_FILENAME})"

    ## Moving GPG data into the coffin, and closing again
    _verbose "coffin" "Copying GPG files in coffin"
    cp -fR ${RAMDISK}/* ${TMP} || _warning "coffin" "Failed to copy one or more files into coffin"
    _verbose "coffin" "Setting GPG files immutable"
    $s chattr +i ${TMP}/private-keys-v1.d/*
    $s chattr +i ${TMP}/openpgp-revocs.d/*
    _verbose "coffin" "Closing coffin"
    sudo umount ${TMP} || _warning "coffin" "Failed to unmount tmp directory ${TMP}"
    sudo cryptsetup close /dev/mapper/${coffin_name} || _failure "coffin" "Failed to close LUKS filesystem for identity"

    # Clearing RAMDisk
    _verbose "ramdisk" "Wiping and unmounting ramdisk"
    sudo wipe -rf ${RAMDISK} || _warning "ramdisk" "Failed to wipe ${RAMDISK} directory"
    sudo umount ${RAMDISK}  || _warning "ramdisk" "Failed to unmount ramdisk ${RAMDISK}"

    ## 5 - Final checks 
    _verbose "coffin" "5) Final checks"
    _verbose "coffin" "Checking directory contents"
    _verbose "$(tree ${HUSH_DIR} ${GRAVEYARD})"
    _verbose "coffin" "Should look like this:           \n\n \
    /home/user/.hush                                    \n    \
        ├── fjdri3kff2i4rjkFA (joe-gpg.key)             \n    \
    /home/user/.graveyard                               \n    \
        ├── fejk38RjhfEf13 (joe-gpg.coffin)"

    _verbose "coffin" "Test opening and closing coffin for ${IDENTITY}"
    open_coffin ${IDENTITY} "${pass}"
    close_coffin ${IDENTITY} "${pass}"

    ## 6 - Removing GPG private keys 
    _verbose "gpg" "6) Removing GPG private keys"

    local GPG_TOMB_LABEL_ENC=$(_encrypt_filename ${IDENTITY} "${GPG_TOMB_LABEL}" "$pass")
    local TOMB_SIZE=15
    local fingerprint=$(gpg -K ${email} | grep fingerprint | head -n 1 | cut -d= -f2 | sed 's/ //g')

    _verbose "gpg" "Creating tomb file for identity ${IDENTITY}"
    new_tomb ${GPG_TOMB_LABEL} ${TOMB_SIZE} "${IDENTITY}" "$pass"
    _verbose "gpg" "Opening tomb file"
    open_tomb ${GPG_TOMB_LABEL} ${IDENTITY}
    local KEYGRIP="$(gpg -K | grep Keygrip | head -n 1 | cut -d= -f 2 | sed 's/ //g').key"
    _verbose "gpg" "Keygrip: ${KEYGRIP}"
    _verbose "gpg" "Copying private data to tomb"
    _verbose "gpg" "Private keys"
    cp ${RAMDISK}/private-keys-v1.d/${KEYGRIP} ${HOME}/.tomb/${GPG_TOMB_LABEL_ENC}/
    _verbose "gpg" "Revocation certificates"
    cp ${RAMDISK}/openpgp-revocs.d/${fingerprint}.rev ${HOME}/.tomb/${GPG_TOMB_LABEL_ENC}/
    _verbose "gpg" "Wiping corresponding files"
    $s chattr -i ${RAMDISK}/private-keys-v1.d/${KEYGRIP} 
    wipe -rf ${RAMDISK}/private-keys-v1.d/${KEYGRIP} || _warning "gpg" "Failed to delete master private key from keyring !"
    $s chattr -i ${RAMDISK}/openpgp-revocs.d/${fingerprint}.rev
    wipe -rf ${RAMDISK}/openpgp-revocs.d/${fingerprint}.rev || _warning "gpg" "Failed to delete master key revocation from keyring !"

    _verbose "gpg" "Printing GPG keyring. Should have 'sec#' instead of 'pub'"
    verbose "$(gpg -K)"
    _verbose "gpg" "Closing GPG tomb file"
    close_tomb ${GPG_TOMB_LABEL} ${IDENTITY}
}

# gpgpass essentially wraps a call to spectre with our identity parameters.
# Note that this function cannot fail because of "a wrong password".
#
# If a second, non-nil argument is passed, we print the passphrase: 
# this is used when some commands need both the passphrase as an input
# to decrypt something (like files) and the user needs them for GPG prompts
gpgpass ()
{
    local identity="$(_identity_active_or_specified ${1})"

    # Since we did not give any input (master) passphrase to this call,
    # spectre will prompt us for an input one. This input is already known
    # to us, since we have used the same when generating the GPG keys.
    #
    # In addition: this call cannot fail because of "a wrong" passphrase.
    # It will just output something, which will or will not (if actually incorrect)
    # work when pasted in further GPG passphrase prompts.
    local passphrase=$(_passphrase ${identity})

	echo -n "${passphrase}" | xclip -selection clipboard
	( sleep ${GPGPASS_TIMEOUT}; echo -n "" |xclip -selection clipboard;) &

    # Return the passphrase is asked to
    if [[ ! -z ${2} ]]; then
        print "${passphrase}"
    else
        _message "risks" "The passphrase has been saved in clipboard     \n \
        Press CTRL+SHIFT+C to share the clipboard with another qube.     \n \
        Local clipboard will be erased is ${GPGPASS_TIMEOUT} seconds"       
    fi
}
