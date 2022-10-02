# validate_file_exists just checks that
validate_file_exists () {
    [[ -e "$1" ]] || echo "Invalid file $1: no such file or directory"
}

# Checks that a partition size given in absolute terms has a valid unit
validate_partition_size () {
    case "$1" in *K|*M|*G|*T|*P) return ;; esac
    echo "Absolute size must comprise a valid unit (K/M/G/T/P, eg. 100M)"
}

# Checks a given device path is encrypted.
validate_is_luks_device () {
    if ! is_encrypted_block  "$1" ; then
        echo "Path $1 seems not to be a LUKS filesystem."
    fi
}

# validate_device is general purpose validator that calls on many of the
# other validations above, because some commands will need all of the
# conditions above to be fulfilled.
validate_device () {

    # Check device file exists
    if [[ ! -e $1 ]]; then
        echo "Device path $1 does not exist: no such file."
    fi
}

# validate_identity_exists simply hashes an identity name and tries to
# find its corresponding coffin file in .graveyard/. If yes, the identity
# exists and is theoretically accessible on this system.
validate_identity_exists () {
    local identity="$1"

    # This might be empty if none have been found, since the _failure
    # call in _identity_active_or_specified is executed in a subshell.
    # We don't care.
    IDENTITY=$(_identity_active_or_specified "$identity")
    FILE_ENCRYPTION_KEY=$(_set_file_encryption_key "$IDENTITY")

    # Stat the coffin
    local coffin_filename coffin_file
    coffin_filename=$(_encrypt_filename "${IDENTITY}-gpg.coffin")
    coffin_file="${GRAVEYARD}/${coffin_filename}"

    if [[ ! -e $coffin_file ]]; then
        echo "Invalid identity $1: no corresponding coffin file found in ~/.graveyard"
    fi
}
