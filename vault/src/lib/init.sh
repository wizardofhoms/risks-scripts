
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
    open_tomb "${PASS_TOMB_LABEL}" "${IDENTITY}"
    _verbose "pass" "Initializating password store with recipient ${email}"
    pass init "${email}"
    _verbose "pass" "Closing pass tomb file"
    close_tomb "${PASS_TOMB_LABEL}" "${IDENTITY}"
}

# Creates a default management tomb in which, between others, the key=value store is being kept.
init_mgmt ()
{
    local IDENTITY="${1}"       
    local passphrase="${2}"

    _verbose "mgmt" "Creating tomb file for management (key=value store, etc)"
    new_tomb "${MGMT_TOMB_LABEL}" 10 "${IDENTITY}" "$passphrase"
    _verbose "mgmt" "Opening management tomb"
    open_tomb "${MGMT_TOMB_LABEL}" "${IDENTITY}"
    _verbose "mgmt" "Closing management tomb"
    close_tomb "${MGMT_TOMB_LABEL}" "${IDENTITY}"
}

# store_risks_scripts copies the various vault risks scripts in a special directory in the
# hush partition, along with a small installation scriptlet, so that upon mounting the hush
# somewhere else, the user can quickly install and use the risks on the new machine.
store_risks_scripts ()
{
    local prg_path="$0"

    _verbose "scripts" "Copying risks scripts onto the hush partition"
    mkdir -p "${RISKS_SCRIPTS_INSTALL_PATH}"
    sudo cp "${prg_path}" "${RISKS_SCRIPTS_INSTALL_PATH}"
    sudo cp /usr/local/share/zsh/site-functions/_risks "${RISKS_SCRIPTS_INSTALL_PATH}"

    cat >"${RISKS_SCRIPTS_INSTALL_PATH}/install" <<'EOL'
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
EOL
}
