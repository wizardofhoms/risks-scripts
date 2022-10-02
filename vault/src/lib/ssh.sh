
# Generate SSH keypair and sets up scripts for loading multiple keypairs
gen_ssh_keys()
{
    local email="$1"

    _verbose "Creating and opening tomb file for SSH"
    _run new_tomb "$SSH_TOMB_LABEL" 20 "$IDENTITY"
    _run open_tomb "$SSH_TOMB_LABEL" "$IDENTITY"

    # Write multi-key loading script
    _verbose "Writing multiple SSH-keypairs loading script (ssh-add)"
    cat >"${HOME}/.ssh/ssh-add" <<'EOF'
#!/usr/bin/env bash
#
# Autostart SSH-agent and autoload all private keys in ~/.ssh directory
#
# How to use:
# - Place this scripts in ~/.bashrc. (We did not here, instead we use a .desktop autostart pointing to here).
# - If ssh-agent is not filled by any private keys, passphrase prompts will show up for each private keys
#

# register ssh key
env=~/.ssh/agent.env

agent_load_env () { test -f "$env" && . "$env" >| /dev/null ; }

agent_start () {
    (umask 077; ssh-agent >| "$env")
    . "$env" >| /dev/null ; }

agent_load_env

# agent_run_state: 0=agent running w/ key; 1=agent w/o key; 2= agent not running
agent_run_state=$(ssh-add -l >| /dev/null 2>&1; echo $?)

if [ ! "$SSH_AUTH_SOCK" ] || [ $agent_run_state = 2 ]; then
    agent_start
    # this will load all private keys in ~/.ssh directory if agent not running
    find ~/.ssh/ -type f -exec grep -l "PRIVATE" {} \; | xargs ssh-add &> /dev/null
elif [ "$SSH_AUTH_SOCK" ] && [ $agent_run_state = 1 ]; then
    # this will load all private keys in ~/.ssh directory if agent is not filled with any private key
    find ~/.ssh/ -type f -exec grep -l "PRIVATE" {} \; | xargs ssh-add &> /dev/null
fi

unset env
EOF
    chmod +x "${HOME}/.ssh/ssh-add" || _warning "Failed to make ssh-add custom script executable"
    
    # Generate keys
    _verbose "Generating keys for identity"
    _run ssh-keygen -t ed25519 -b 4096 -C "$email" -N "" -f "${HOME}"/.ssh/id_ed25519 # No passphrase
    _verbose "Making keys immutable"
    sudo chattr +i "${HOME}"/.ssh/id_ed25519*
    _verbose "Closing SSH tomb file"
    _run close_tomb "$SSH_TOMB_LABEL" "$IDENTITY"
}
