## Config functions [@bashly-upgrade config]
## This file is a part of Bashly standard library
##
## Usage:
## - In your script, set the CONFIG_FILE variable. For rxample:
##   CONFIG_FILE=settings.ini.
##   If it is unset, it will default to 'config.ini'.
## - Use any of the functions below to access the config file.
##
## Create a new config file.
## There is normally no need to use this function, it is used by other
## functions as needed.
##
config_init() {
  RISK_CONFIG_FILE=${RISK_CONFIG_FILE-${RISK_DIR}/config.ini}
  [[ -f "$RISK_CONFIG_FILE" ]] || { 
      _message "Writing default configuration file to ${RISK_CONFIG_FILE}"
      cat << EOF > "$RISK_CONFIG_FILE" 
; RISKS Dom0 Configuration file

; You can either edit this file in place, set values
; through the 'risk config' command, or reload it with
; 'risk config reload'.
;
; Default Templates =============================================== #

; Default Whonix Workstation TemplateVM for TOR clients
WHONIX_WS_TEMPLATE=whonix-ws-16

; Default Whonix Gateway TemplateVM for TOR gateways
WHONIX_GW_TEMPLATE=whonix-gw-16

; Default TemplateVM to use for VPN VMs
VPN_TEMPLATE=sys-vpn

; Default TemplateVM to use for split-browser backend
SPLIT_BROWSER_TEMPLATE=

; Default AppVMs ================================================== #
;
; These VMs are used when we create new machines by cloning
; existing ones, instead of creating blank AppVMs from templates.

; Default Whonix Workstation AppVM to use for identity client machine
WHONIX_WS=

; Default AppVM to use for cloning new VPN qubes
VPN_VM=

; Default AppVM to clone for split-browser backend
SPLIT_BROWSER=

; Vault settings ================================================== #

; Default vault VM
VAULT_VM=vault

; Qubes path to hush device, such as 'dom0:mmcblk01', or 'sys-usb:sda2', etc
SDCARD_BLOCK=

; Qubes path to backup device, such as 'sys-usb:sdb1'
BACKUP_BLOCK=

; Other network settings ========================================= #

; Default VM to use as a firewall VM, to which either Tor or VPN gateways are bound
DEFAULT_NETVM=sys-firewall

; Default path to VPN client config in VPN VM, to be loaded when the service
; starts. This path is the default one used by qubes-vpn-support installs.
DEFAULT_VPN_CLIENT_CONF='/rw/config/vpn/vpn-client.conf'

EOF
  }
}

## Get a value from the config.
## Usage: result=$(config_get hello)
config_get() {
  # zsh compat
  setopt local_options BASH_REMATCH

  local key=$1
  local regex="^$key *= *(.+)$"
  local value=""

  config_init
  
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ $line =~ $regex ]]; then
      value="${BASH_REMATCH[2]}" # Changed to 2 because ZSH indexes start at 1
      break
    fi
  done < "$RISK_CONFIG_FILE"

  echo "$value"
}

## Add or update a key=value pair in the config.
## Usage: config_set key value
config_set() {
  # zsh compat
  setopt local_options BASH_REMATCH

  local key=$1
  shift
  local value="$*"

  config_init

  local regex="^($key) *= *.+$"
  local output=""
  local found_key=""
  local newline
  
  while IFS= read -r line || [ -n "$line" ]; do
    newline=$line
    if [[ $line =~ $regex ]]; then
      found_key="${BASH_REMATCH[2]}"
      newline="$key = $value"
      output="$output$newline\n"
    elif [[ $line ]]; then
      output="$output$line\n"
    fi
  done < "$RISK_CONFIG_FILE"

  if [[ -z $found_key ]]; then
    output="$output$key = $value\n"
  fi

  printf "%b\n" "$output" > "$RISK_CONFIG_FILE"
}

## Delete a key from the config.
## Usage: config_del key
config_del() {
  local key=$1

  local regex="^($key) *="
  local output=""

  config_init

  while IFS= read -r line || [ -n "$line" ]; do
    if [[ $line ]] && [[ ! $line =~ $regex ]]; then
      output="$output$line\n"
    fi
  done < "$RISK_CONFIG_FILE"

  printf "%b\n" "$output" > "$RISK_CONFIG_FILE"
}

## Show the config file
config_show() {
  config_init
  cat "$RISK_CONFIG_FILE"
}

## Return an array of the keys in the config file.
## Usage:
##
##   for k in $(config_keys); do
##     echo "- $k = $(config_get "$k")";
##   done
##
config_keys() {
  # zsh compat
  setopt local_options BASH_REMATCH

  local regex="^([a-zA-Z0-9_\-\/\.]+) *="

  config_init

  local keys=()
  local key
  
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ $line =~ $regex ]]; then
      key="${BASH_REMATCH[1]}"
      key="${key//\=/}"
      [[ -n "$key" ]] && keys+=("$key")
    fi
  done < "$RISK_CONFIG_FILE"
  echo "${keys[@]}"
}

## Returns true if the specified key exists in the config file.
## Usage:
##
##   if config_has_key "key" ; then
##     echo "key exists"
##   fi
##
config_has_key() {
  [[ $(config_get "$1") ]]
}
