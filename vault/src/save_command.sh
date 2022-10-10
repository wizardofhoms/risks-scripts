
local source_vm resource source_dir dest_dir

source_vm="${args[source_vm]}"    
resource="${args[resource]}"   # Resource is a tomb file (root directory) in ~/.tomb

_set_identity "${args[identity]}"

# Make the source directory 
# Don't do anything if the directory does not exist
source_dir="${HOME}/QubesIncoming/${source_vm}"
if [[ ! -d $source_dir ]]; then
    _failure "No QubesIncoming directory found for $source_vm"
fi

# Open the related tomb for the tool 
_run open_tomb "$resource"
_catch "Failed to open tomb"

# And make the destination directory
dest_dir="${HOME}/.tomb/${resource}"

# Or move the data from the directory to the tomb directory
_message "Moving data to tomb $resource directory"
mv "${source_dir}/"'*' "$dest_dir"

# And close tomb if asked to
if [[ "${args[--close-tomb]}" -eq 1 ]]; then
    _message "Closing tomb"
    _run close_tomb "$resource"
fi
