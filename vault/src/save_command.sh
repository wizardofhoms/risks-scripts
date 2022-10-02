
SOURCE_VM="${args[source_vm]}"    
RESOURCE="${args[resource]}"   # Resource is a tomb file (root directory) in ~/.tomb

_set_identity "${args[identity]}"

local source_dir dest_dir

# Make the source directory 
# Don't do anything if the directory does not exist
source_dir="${HOME}/QubesIncoming/${SOURCE_VM}"
if [[ ! -d $source_dir ]]; then
    _failure "No QubesIncoming directory found for $SOURCE_VM"
fi

# Open the related tomb for the tool 
_run open_tomb "$RESOURCE"
_catch "Failed to open tomb"

# And make the destination directory
dest_dir="${HOME}/.tomb/${RESOURCE}"

# Or move the data from the directory to the tomb directory
_message "Moving data to tomb $RESOURCE directory"
mv "${source_dir}/"'*' "$dest_dir"

# And close tomb if asked to
if [[ "${args[--close-tomb]}" -eq 1 ]]; then
    _message "Closing tomb"
    _run close_tomb "$RESOURCE"
fi
