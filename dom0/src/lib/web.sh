
# Create a web browsing VM from a template
create_browser_vm ()
{
    local web="${1}-web"
    local netvm="${2-$RISK_DEFAULT_NETVM}"
    local web_label="${3-orange}"

    local -a create_command
    create_command+=(qvm-create --property netvm="$netvm" --label "$web_label" --template "$WHONIX_WS_TEMPLATE")

    _message "Creating web VM (name: $web / netvm: $netvm / template: $WHONIX_WS_TEMPLATE)"
}

# Clone a web browsing VM from an existing one
clone_browser_vm ()
{
    local web="${1}-web"
    local web_clone="$2"
    local netvm="${3-$RISK_DEFAULT_NETVM}"
    local web_label="${4-orange}"

    create_command+=(qvm-clone "${web_clone}" "${web}")

    local label_command=(qvm-prefs "$web" label "$web_label")
    local netvm_command=(qvm-prefs "$web" netvm "$netvm")

    _message "Cloning web VM (name: $web / netvm: $netvm / template: $web_clone)"
}

# Create a split-browser VM from a template
create_split_browser_vm ()
{
    local web="${1}-split-web"
    local web_label="${2-gray}"

    local -a create_command
    create_command+=(qvm-create --property netvm=None --label "$web_label" --template "$RISK_SPLIT_BROWSER_TEMPLATE")

    _message "Creating split-browser (name: $web / netvm: $netvm / template: $RISK_SPLIT_BROWSER_TEMPLATE)"
}

# Clone an existing split-browser VM, and change its dispvms
clone_split_browser_vm ()
{
    local web="${1}-split-web"
    local web_clone="$2"
    local web_label="${3-gray}"

    create_command+=(qvm-clone "${web_clone}" "${web}")

    local label_command=(qvm-prefs "$web" label "$web_label")
    local netvm_command=(qvm-prefs "$web" netvm None)

    _message "Cloning split-browser VM (name: $web / netvm: $netvm / template: $web_clone)"
}
