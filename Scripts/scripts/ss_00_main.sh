#!bin/bash

# standup.sh

# TODO: Get opinion on `` vs $() as backticks are portable to legacy shells

set +ex

# If script not sourced, stop here
if [[ "$0" = "$BASH_SOURCE" ]]; then
    echo "This script must be sourced like so: \"source standup.sh\""
    return 1
fi

MESSAGE_PREFIX="-------Standup -"

####
# Environment Variables
####

# system
NOPROMPT=false
VPS=false
USERPASSWORD=""

# vps
FQDN=""
HOSTNAME=""
REGION=""

# bitcoind
NETWORK="mainnet"
PRUNE=""
FASTSYNC=false
HWI=true

# lightning
LIGHTNING="c-lightning"
LN_ALIAS="StandUp"

# services
ESPLORA=false
BTCPAYSERVER=false

# Tor & SSH
TOR_PUBKEY=""
SSH_KEY=""
SYS_SSH_IP=""

# btcpay server
BTCPAY_HOST=""
BTCPAY_LN="c-lightning"

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
    -y)
      NOPROMPT=true
      shift 1
      ;;
    --vps)
      VPS=true
      shift 1
      ;;
    --userpassword)
      USERPASSWORD="$2"
      shift 1
      shift 1
      ;;
    -F|--fqdn)
      FQDN="$2"
      shift 1
      shift 1
      ;;
    -H|--hostname)
      HOSTNAME=$2
      shift 1
      shift 1
      ;;
    -R|--region)
      REGION=$2
      shift 1
      shift 1
      ;;
    -n|--network)
      if [ "${2:0:1}" = "-" ]; then
        echo "Network flag passed without value. Installing default network: mainnet."
      shift 1
      elif [[ -n "$2" ]] && [[ "$2" = "mainnet" ]] || [[ "$2" = "testnet" ]] || [[ "$2" = "regtest" ]]; then
        NETWORK="$2"
      else
        echo "ERROR: Network has to be either mainnet, testnet or regtest. Passed $2"
        while [[ "$NETWROK" != "mainnet" ]] || [[ "$NETWROK" != "testnet" ]] || [[ "$NETWROK" != "regtest" ]]; do
          read -pr "Enter which network do you want to default to: " NETWORK
        done
      fi
      shift 1
      shift 1
      ;;
    -p|--prune)
      if [ "${2:0:1}" = "-" ]; then
        echo "Prune flag passed without value. Installing default: unpruned node."
      shift 1
      elif [[ -n "$2" ]] && [[ "$2" -ge 550 ]]; then
        PRUNE="$2"
      else
        echo "ERROR: Minimum prune value is 550. Passed $2"
        # while [[ "$PRUNE" -lt 550 ]]; do
        #   read -pr "Enter a value above 550 or 0 if you want to install an unpruned node (you can change this later): " PRUNE
        # done
        return 1
      fi
      shift 1
      shift 1
      ;;
    --fastsync)
      FASTSYNC=true
      shift 1
      ;;
    --no-hwi)
      HWI=false
      shift 1
      ;;
    --no-ln)
      LIGHTNING=false
      shift 1
      ;;
    -l|--lightning)
      if [ "${2:0:1}" = "-" ]; then
        echo "Lightning flag passed without specifying the implementation. Installing default implementation: c-lightning"
      shift 1
      elif [[ -n "$2" ]] && [[ "$2" = "c-lightning" ]] || [[ "$2" = "lnd" ]]; then
        LIGHTNING="$2"
      else
        echo "ERROR: Invalid lightning implementation. Pass 'c-lightning' or 'lnd'. Passed $2."
        return 1
      fi
      shift 1
      shift 1
      ;;
    --ln-alias)
      LN_ALIAS="$2"
      shift 1
      shift 1
      ;;
    -t|--tor-pubkey)
      TOR_PUBKEY="$2"
      shift 1
      shift 1
      ;;
    --ssh-key)
      SSH_KEY="$2"
      shift 1
      shift 1
      ;;
    --sys-ssh-ip)
      SYS_SSH_IP="$2"
      shift 1
      shift 1
      ;;
    --esplora)
      ESPLORA=true
      shift 1
      ;;
    --btcpay)
      BTCPAYSERVER=true
      shift 1
      ;;
    --btcpay-host)
      BTCPAY_HOST="$2"
      shift 1
      shift 1
      ;;
    --btcpay-ln)
      BTCPAY_LN="$2"
      shift 1
      shift 1
      ;;
    --) # end argument parsing
      shift 1
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      help
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


#STARTUP_REGISTER..: $STARTUP_REGISTER
#SYSTEMD_RELOAD....: $SYSTEMD_RELOAD

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

# ####
# # RESET Environment Variables
# ####

# # system
# NOPROMPT=false
# STARTUP_REGISTER=true
# SYSTEMD_RELOAD=true
# VPS=false
# USERPASSWORD=""

# # vps
# FQDN=""
# HOSTNAME=""
# REGION=""

# # bitcoind
# NETWORK="mainnet"
# PRUNE=""
# FASTSYNC=false
# HWI=true

# # lightning
# LIGHTNING="c-lightning"

# # services
# ESPLORA=false
# BTCPAYSERVER=false

# # Tor
# TOR_PUBKEY=""

# # ssh
# SSH_KEY=""
# SYS_SSH_IP=""


# Finished, exit script
exit 0
