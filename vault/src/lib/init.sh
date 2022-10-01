
# This file contains additional IDENTITY initialization functions.

## Creates a tomb storing the password-store and sets the latter up 
init_pass () 
{
    local IDENTITY="${1}"       
    local email="${2}"

    _verbose "Creating tomb file for pass"
    _run new_tomb "$PASS_TOMB_LABEL" 20 "$IDENTITY"
    _verbose "Opening password store"
    _run open_tomb "$PASS_TOMB_LABEL" "$IDENTITY"
    _verbose "Initializating password store with recipient $email"
    _run pass init "$email"
    _verbose "Closing pass tomb file"
    _run close_tomb "$PASS_TOMB_LABEL" "$IDENTITY"
}

# Creates a default management tomb in which, between others, the key=value store is being kept.
init_mgmt ()
{
    local IDENTITY="${1}"       

    _verbose "Creating tomb file for management (key=value store, etc)"
    _run new_tomb "$MGMT_TOMB_LABEL" 10 "$IDENTITY"
    _verbose "Opening management tomb"
    _run open_tomb "$MGMT_TOMB_LABEL" "${IDENTITY}"
    _verbose "Closing management tomb"
    _run close_tomb "$MGMT_TOMB_LABEL" "$IDENTITY"
}

# store_risks_scripts copies the various vault risks scripts in a special directory in the
# hush partition, along with a small installation scriptlet, so that upon mounting the hush
# somewhere else, the user can quickly install and use the risks on the new machine.
store_risks_scripts ()
{
    _message "Copying risks scripts onto the hush partition"
    mkdir -p "$RISKS_SCRIPTS_INSTALL_PATH"
    sudo cp "$(which risks)" "$RISKS_SCRIPTS_INSTALL_PATH"
    sudo chmod go-rwx "$RISKS_SCRIPTS_INSTALL_PATH"
    sudo cp /usr/local/share/zsh/site-functions/_risks "$RISKS_SCRIPTS_INSTALL_PATH"

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
sudo chmod go-rwx "${INSTALL_SCRIPT_PATH}"
sudo chmod u+x "${INSTALL_SCRIPT_PATH}"

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
