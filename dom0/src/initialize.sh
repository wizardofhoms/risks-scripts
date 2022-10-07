#!/usr/bin/env bash

# Connected terminal
typeset -H _TTY
GPG_TTY=$(tty)  # Needed for GPG operations
export GPG_TTY

# Remove verbose errors when * don't yield any match in ZSH
setopt +o nomatch

# Working state variables
typeset -r IDENTITY            # The identity to use for this single risk execution
typeset -g IDENTITY_DIR        # The directory where to store identity settings

# Default templates and VMs to use

typeset -rg WHONIX_GW_TEMPLATE="whonix-gw-16"
typeset -rg WHONIX_WS_TEMPLATE="whonix-ws-16"

# Working state and configurations
typeset -rg RISK_DIR="${HOME}/.risk"                         # Directory where risk stores its state
typeset -rg RISK_IDENTITIES_DIR="${RISK_DIR}/identities"     # Idendities store their settings here
typeset -rg RISK_IDENTITY_FILE="${RISK_DIR}/.identity"

#----------------------------#
## Checks ##

# Don't run as root
if [[ $EUID -eq 0 ]]; then
   echo "This script must be run as user"
   exit 2
fi

# Use colors unless told not to
{ ! option_is_set --no-color } && { autoload -Uz colors && colors }


#----------------------------#
## Configuration directories ##

# Create the risk directory if needed
[[ -e $RISK_DIR ]] || { mkdir -p $RISK_DIR && _message "Creating RISK directory in $RISK_DIR" }
[[ -e $RISK_IDENTITIES_DIR ]] || mkdir -p $RISK_IDENTITIES_DIR

# Write the default configuration if it does not exist.
config_init
