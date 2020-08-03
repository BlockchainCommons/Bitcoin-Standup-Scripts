#!bin/bash

# standup.sh

# TODO: Get opinion on `` vs $() as backticks are portable to legacy shells

set +ex

# If script not sourced, stop here
if [[ "$0" = "$BASH_SOURCE" ]]; then
    echo "This script must be sourced like so: \"source standup.sh\""
    return 1
fi

# message formatting variables
MESSAGE_PREFIX="-------Standup -"
bold=$(tput bold)
normal=$(tput sgr0)
underline=$(tput smul)

####
# Parsing Config file
####

config_read_file() {
    (grep -E "^${2}=" -m 1 "${1}" 2>/dev/null || echo "VAR=__UNDEFINED__") | head -n 1 | cut -d '=' -f 2-;
}

config_get() {
    val="$(config_read_file ./ss.conf "${1}")";
    if [ "${val}" = "__UNDEFINED__" ]; then
        val="$(config_read_file ./ss.conf.defaults "${1}")";
    fi
    printf -- "%s" "${val}";
}

# system
NOPROMPT="$(config_get NOPROMPT)"
VPS="$(config_get VPS)"
USERPASSWORD="$(config_get USERPASSWORD)"

# vps
FQDN="$(config_get FQDN)"
HOSTNAME="$(config_get HOSTNAME)"
REGION="$(config_get REGION)"

# bitcoind
NETWORK="$(config_get NETWORK)"
PRUNE="$(config_get PRUNE)"
FASTSYNC="$(config_get FASTSYNC)"
HWI="$(config_get HWI)"

# lightning
LIGHTNING="$(config_get LIGHTNING)"
LN_ALIAS="$(config_get LN_ALIAS)"

# services
ESPLORA="$(config_get ESPLORA)"
BTCPAYSERVER="$(config_get BTCPAYSERVER)"

# Tor & SSH
TOR_PUBKEY="$(config_get TOR_PUBKEY)"
SSH_KEY="$(config_get SSH_KEY)"
SYS_SSH_IP="$(config_get SYS_SSH_IP)"

# btcpay server
BTCPAY_HOST="$(config_get BTCPAY_HOST)"
BTCPAY_LN="$(config_get BTCPAY_LN)"

####
# Parsing Arguments
####
PARAMS=""

while (( "$#" )); do
key="$1"
  case $key in
    -h|--help)
      source ./ss_01_help.sh
      return 3
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      source ./ss_01_help.sh
      return 7
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift 1
      ;;
  esac
done
set -- "$PARAMS"  # set positional parameters in order


####
# 0. Force check for root
####

# if you are not logged in as root then the script will not execute
echo "
----------------"
echo "$MESSAGE_PREFIX Checking if logged in as root."
echo "----------------"
if ! [ "$(id -u)" == 0 ]; then
  echo "$MESSAGE_PREFIX You need to be logged in as root!"
  return 2
fi

echo "$MESSAGE_PREFIX Logged in as root. Continuing with installation.
----------------
"
# Output stdout and stderr to ~root files
exec > >(tee -a /root/standup.log) 2> >(tee -a /root/standup.log /root/standup.err >&2)



# Display script configuration
echo "
---------SETUP---------
Parameters Passed:

System
------
NOPROMPT......: $NOPROMPT
VPS...........: $VPS
USERPASSWORD..: $USERPASSWORD

VPS
---
FQDN..........: $FQDN
HOSTNAME......: $HOSTNAME
REGION........: $REGION

Bitcoin
--------
NETWORK.......: $NETWORK
PRUNE.........: $PRUNE
FASTSYNC......: $FASTSYNC
HWI...........: $HWI

Lightning
----------
LIGHTNING.....: $LIGHTNING
LN_ALIAS......: $LN_ALIAS

Services
---------
ESPLORA.......: $ESPLORA
BTCPAYSERVER..: $BTCPAYSERVER

Tor & SSH
----------
TOR_PUBKEY....: $TOR_PUBKEY
SSH_KEY.......: $SSH_KEY
SYS_SSH_IP....: $SYS_SSH_IP

BTCPAY Server
-------------
BTCPAY_HOST...: $BTCPAY_HOST
BTCPAY_LN.....: $BTCPAY_LN
"


####
# 1. Update Hostname and set timezone
####
# source vps setup script
if "$VPS"; then
  source ./ss_00.1_vps.sh
fi


# prompt user before continuing with installation
if ! "$NOPROMPT"; then
  read -rp  "Continue with installation? (Y/n): " confirm
fi

if [[ "$confirm" != [yY] ]]; then
  echo "Entered $confirm. Exiting.."
  return 8
else
  NOPROMPT=true
  echo "Installing Bitcoin!"
fi


####
# 2. Update Debian, Set autoupdate and Install Dependencies
####
echo "
----------------
$MESSAGE_PREFIX Starting Debian updates; this will take a while!
----------------
"

# Make sure all packages are up-to-date
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

# source dependency script
source ./ss_02_dependencies.sh


####
# 3. Create user admin
####
# source user and ssh script
source ./ss_03_user_ssh.sh


####
# 4. Install Tor
####
# source tor script
source ./ss_04_tor.sh

# sleep 4 seconds for tor to restart
sleep 4

####
# 5. Install Bitcoin
####
# source bitcoin script
BITCOIND_VERSION=$(bitcoind --version | grep "Bitcoin Core version | awk '{print $4}'")
if [[ -n "$BITCOIND_VERSION" ]]; then
  echo "
  ----------------
  $MESSAGE_PREFIX bitcoind is already installed, version: $BITCOIND_VERSION
  ----------------
  "
  return 0
else
  source ./ss_05_bitcoin.sh
fi

sleep 4

echo "

----------------

  $MESSAGE_PREFIX bitcoind service is: $(systemctl status bitcoind | grep active | awk '{print $2}')

----------------
"

####
# Lightning
####
# source lightning script
if [[ "$LIGHTNING" = "c-lightning" ]]; then
  source ./ss_06_c-lightning.sh
else
  source ./ss_06_lnd.sh
fi


####
# BTCPay Server
####
# source btcpay script
if "$BTCPAYSERVER"; then
  source ./ss_07_btcpayserver.sh
fi

# Finished, exit script
return 0
