
# Create a web browsing VM from a template
create_browser_vm ()
{
    local web="${1}-web"
    local netvm="${2-$RISK_DEFAULT_NETVM}"
    local web_label="${3-orange}"

    _message "Creating web VM (name: $web / netvm: $netvm / template: $WHONIX_WS_TEMPLATE)"
    qvm-create --property netvm="$netvm" --label "$web_label" --template "$WHONIX_WS_TEMPLATE"
    [[ ! $? -eq 0 ]] && _warning "Failed to create browser VM $web"

    # Mark this VM as a disposable template, and tag it with our identity
    qvm-prefs "${web}" template_for_dispvms True
    qvm-tags "$web" set "$IDENTITY"
}

# Clone a web browsing VM from an existing one
clone_browser_vm ()
{
    local web="${1}-web"
    local web_clone="$2"
    local netvm="${3-$RISK_DEFAULT_NETVM}"
    local web_label="${4-orange}"

    _message "Cloning web VM (name: $web / netvm: $netvm / template: $web_clone)"
    qvm-clone "${web_clone}" "${web}"
    [[ ! $? -eq 0 ]] && _warning "Failed to clone browser VM $web" && return

    qvm-prefs "$web" label "$web_label"
    qvm-prefs "$web" netvm "$netvm"

    # Mark this VM as a disposable template, and tag it with our identity
    qvm-prefs "${web}" template_for_dispvms True
    qvm-tags "$web" set "$IDENTITY"
}

# Create a split-browser VM from a template
create_split_browser_vm ()
{
    local web="${1}-split-web"
    local web_label="${2-gray}"

    _message "Creating split-browser (name: $web / netvm: $netvm / template: $RISK_SPLIT_BROWSER_TEMPLATE)"
    qvm-create --property netvm=None --label "$web_label" --template "$RISK_SPLIT_BROWSER_TEMPLATE"
}

# Clone an existing split-browser VM, and change its dispvms
clone_split_browser_vm ()
{
    local web="${1}-split-web"
    local web_clone="$2"
    local web_label="${3-gray}"

    _message "Cloning split-browser VM (name: $web / netvm: $netvm / template: $web_clone)"
    qvm-clone "${web_clone}" "${web}"

    qvm-prefs "$web" label "$web_label"
    qvm-prefs "$web" netvm None
}
