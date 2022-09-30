
# Loads copies some data needed by some tool on another VM. Generally a script
# in the said VM should be invoked so as to move to the date to its final destination.
load()
{
    # Parameters
	local IDENTITY="${1}"
    local RESOURCE="${2}"   # Resource is a tomb file (root directory) in ~/.tomb
    local DEST_VM="${3}"    

    # Open the related tomb for the tool 
    open_tomb ${RESOURCE} ${IDENTITY} --silent || _failure "${RESOURCE}" "Failed to open tomb"

    # Get the source directory, and copy the files to the VM
    _message "Loading data in tomb $RESOURCE to VM ${DEST_VM}"
	local source_dir="${HOME}/.tomb/${RESOURCE}"
    qvm-copy-to-vm "${DEST_VM}" "${source_dir}/"'*'
}

# Repatriate all data coming from a given VM, but not using this VM name as a parameter.
# Generally, the argument is something like "signal", for which this program knows that
# the data is in "msg" VM, if not otherwise specified by the 3rd argument (optional)
save () 
{
	local IDENTITY="${1}"
    local SOURCE_VM="${2}"
	local RESOURCE="${3}"

    # Make the source directory 
    # Don't do anything if the directory does not exist
    local source_dir="${HOME}/QubesIncoming/${SOURCE_VM}"
    if [[ ! -d $source_dir ]]; then
        _failure "${RESOURCE}" "No QubesIncoming directory found for ${SOURCE_VM}"
    fi

    # Open the related tomb for the tool 
    open_tomb ${RESOURCE} ${IDENTITY} --silent || _failure "${RESOURCE}" "Failed to open tomb"

    # And make the destination directory
	local dest_dir="${HOME}/.tomb/${RESOURCE}"
    
    # Or move the data from the directory to the tomb directory
    _message "Moving data to tomb ${RESOURCE} directory"
    mv "${source_dir}/"'*' "${dest_dir}"
}
