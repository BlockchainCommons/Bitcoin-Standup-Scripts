#!/bin/bash

# standup.sh

set +x

# If script not sourced, stop here
if [[ "$0" = "$BASH_SOURCE" ]]; then
    echo "This script must be sourced like so: \"source standup.sh\""
    return 1
fi

####
# Environment Variables
####

# system
NOPROMPT=false
# STARTUP_REGISTER=true
# SYSTEMD_RELOAD=true
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

# services
ESPLORA=false
BTCPAYSERVER=false

# Tor
TOR_PUBKEY=""

# ssh
SSH_KEY=""
SYS_SSH_IP=""



####
# Parsing Arguments
####
PARAMS=""

while (( "$#" ))
do
key="$1"
  case $key in
    -h|--help)
      source ./ss_help.sh
      return 3
      ;;
    -y)
      NOPROMPT=true
      shift 1
      ;;
    # --no-startup-register)
    #   STARTUP_REGISTER=false
    #   shift 1
    #   ;;
    # --no-systemd-reload)
    #   SYSTEMD_RELOAD=false
    #   shift 1
    #   ;;
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
      if [ "${2:0:1}" == "-" ]
      then
        echo "Network flag passed without value. Installing default network: mainnet."
      shift 1
      elif [[ -n "$2" ]] && [[ "$2" == "mainnet" ]] || [[ "$2" == "testnet" ]] || [[ "$2" == "regtest" ]]
      then
        NETWORK="$2"
      else
        echo "ERROR: Network has to be either mainnet, testnet or regtest. Passed $2"
        return 4
      fi
      shift 1
      shift 1
      ;;
    -p|--prune)
      if [ "${2:0:1}" == "-" ]
      then
        echo "Prune flag passed without value. Installing default: unpruned node."
      shift 1
      elif [[ -n "$2" ]] && [[ "$2" -ge 550 ]]
      then
        PRUNE="$2"
      else
        echo "ERROR: Minimum prune value is 550. Passed $2"
        return 5
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
    -l|--lightning)
      if [ "${2:0:1}" == "-" ]
      then
        echo "Lightning flag passed without specifying the implementation. Installing default implementation: c-lightning"
      shift 1
      elif [[ -n "$2" ]] && [[ "$2" == "c-lightning" ]] || [[ "$2" == "lnd" ]]
      then
        LIGHTNING="$2"
      else
        echo "ERROR: Invalid lightning implementation. Pass c-lightning or lnd. Passed $2"
        return 6
      fi
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
echo "$0 - Checking if logged in as root."
echo "----------------"
if ! [ "$(id -u)" = 0 ]
then
  echo "$0 - You need to be logged in as root!"
  return 2
fi

echo "$0 - Logged in as root. Continuing with installation."
echo "----------------
"
# Output stdout and stderr to ~root files
exec > >(tee -a /root/standup.log) 2> >(tee -a /root/standup.log /root/standup.err >&2)



echo "
---------SETUP---------
Parameters Passed:

System
------
NOPROMPT..........: $NOPROMPT
STARTUP_REGISTER..: $STARTUP_REGISTER
SYSTEMD_RELOAD....: $SYSTEMD_RELOAD
VPS...............: $VPS
USERPASSWORD......: $USERPASSWORD

VPS
---
FQDN......: $FQDN
HOSTNAME..: $HOSTNAME
REGION....: $REGION

Bitcoin:
--------
NETWORK...: $NETWORK
PRUNE.....: $PRUNE
FASTSYNC..: $FASTSYNC
HWI.......: $HWI

Lightning:
----------
LIGHTNING..: $LIGHTNING

Services:
---------
ESPLORA.......: $ESPLORA
BTCPAYSERVER..: $BTCPAYSERVER

Tor & SSH:
----------
TOR_PUBKEY..: $TOR_PUBKEY
SSH_KEY.....: $SSH_KEY
SYS_SSH_IP..: $SYS_SSH_IP
"


####
# 1. Update Hostname and set timezone
####

if "$VPS"
then
  source ./ss_vps.sh
fi



####
# 2. Update Debian, Set autoupdate and Install Dependencies
####

echo "
----------------
"
echo "$0 - Starting Debian updates; this will take a while!"
echo "
----------------
"

# Make sure all packages are up-to-date
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y


# call dependency script
source ./ss_dependencies.sh


####
# 3. Create user admin
####
# call user and ssh script
source ./ss_user_ssh.sh


####
# 4. Install Tor
####
# call tor script
source ./ss_tor.sh

# sleep 4 seconds for tor to restart
sleep 4

####
# 5. Install Bitcoin
####
# call the bitcoin script
source ./ss_bitcoin.sh


####
# Lightning
####



####
# RESET Environment Variables
####

# system
NOPROMPT=false
STARTUP_REGISTER=true
SYSTEMD_RELOAD=true
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

# services
ESPLORA=false
BTCPAYSERVER=false

# Tor
TOR_PUBKEY=""

# ssh
SSH_KEY=""
SYS_SSH_IP=""


# Finished, exit script
exit 0
