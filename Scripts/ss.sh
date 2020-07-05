#!/bin/bash

# standup.sh

set +x

# If script not sourced, stop here
if [[ "$0" = "$BASH_SOURCE" ]]; then
    echo "This script must be sourced like so: \"source standup.sh\""
    return
fi

# define help
function help () {
cat <<-END
--------------------------------------
Install StandUp Script on this server.
--------------------------------------

standup.sh

Blockchain Commons Standup Script
Contributor: jodobear 20-07-03

DISCLAIMER: It is not a good idea to store large amounts of Bitcoin on a VPS,
ideally you should use this as a watch-only wallet. This script is expiramental
and has not been widely tested. The creators are not responsible for loss of
funds. If you are not familiar with running a node or how Bitcoin works then we
urge you to use this in testnet so that you can use it as a learning tool.

TL;DR:
------

1. Using cli arguments:
-----------------------
$ source ./ss.sh -y --userpassword <password> -n testnet -p 10000 --no-hwi -l lnd --btcpay --esplora --tor-pubkey <tor-pubkey> --ssh-key <ssh-key> --sys-ssh-ip <ip_1, ip_2, ..>

This will first create a new user "standup" and set the <password> for that user. Then install Bitcoin Testnet pruned to 10000 Mb with no HWI, LND, BTCPAY Server, Esplora Server on the machine pre-authenticated with Tor so all communications are by default routed through Tor (even the installation data requirements). It willadd the passed SSH Key to authorized hosts and add the comma separated list of IPs to the whitelist.

2. Exporting environment variables:
-----------------------------------
$ export NOPROMPT=true
$ export USERPASSOWRD=password
$ export NETWORK=testnet
$ export LIGHTNING=lnd
$ source ./ss.sh

This will first create a new user "standup" and set the <password> for that user. Then install a full bitcoin node on testnet with lnd.



This script can be installed on any Debian based system. By default this script will:

* Update the OS
* Set Automatic Updates On
* Create User: standup
* Install UFW
* Install Tor
* Install Bitcoin Core
* Install HWI
* Install c-lightning
* Setup Bitcoin Core, Lightning settings
* Make sure they start at reboot via upstart or systemd
* Start Bitcoin Core, Lightning

Optionally you can install:
---------------------------
* Install LND instead of c-lightning
* Install Esplora
* Install BTCPay

You can run this script again if you desire to change your configuration.

Upon completion of the script their will be a QR code saved to /qrcode.png which
you can open and scan. You can use "$ sudo apt-get install fim" then:
"$ fim -a qrcode.png" to display the QR in a terminal (as root).

It is highly recommended to add a Tor V3 pubkey for cookie authentication so that
even if your QR code is compromised an attacker would not be able to access your
node. It is also recommended to delete the /qrcode.png, /standup.log, and
/standup.err files.

--------------------------------------
|                Usage                |
--------------------------------------

0. Prerequisites
----------------

In order to run this script you need to be logged in as root, and enter in the commands listed below:

- The $ or $ represents a terminal commmand prompt, do not actually type in a $ or #.
- Data fields enclosed in <> are to be filled by you with appropriate values.

1. Give the root user a password, enter the following command and set a password:
$ sudo passwd

2. Switch to the root user:
$ su - root

3. Source the script:
# source standup.sh

NOTE: Before sourcing the script you may want to set certain environment variables. Bleow you will find the list of environment variables. To set the variables do:
#export <ENV_VARIABLE>=<value>

You can use the following optional arguments:

    -h --help : Display this help.
    -y : Install without prompting for confirming the setup

    Setup:
    ------
    --no-startup-register : Do not set Bitcoind & Lightning to start after reboot.
    --no-systemd-reload : Do not set Bitcoind & Lightning to start after crash.
    -v --vps : Pass when installing on a VPS.
    --userpassword : Password for the standup non-privileged account.

    VPS:
    ----
    -F --fqdn : Fully Qualified Hostname
    -H --hostname : Hostname of your server
    -R --region : Server's timezone location

    Bitcoin:
    --------
    -f --fastsync : Enables fast synchronization of blockchain*.
    -n --network : Default bitcoin network; either "mainnet", "testnet" or "regtest".
    --no-hwi : Do NOT install HWI.
    -p --prune : Install a prune node; integer value > 550.

    Lightning:
    ----------
    -l --lightning : Choose lightning implementation, either "c-lightning" or "lnd".

    Services:
    ---------
    --btcpay : Installs BTCPay Server.
    --esplora : Installs Esplora.

    Tor:
    ----
    -t --tor-pubkey : Automatically add the pubkey to the Tor authorized_clients directory, which means the user is Tor authenticated before the node is even installed. e.g. ./standup.sh --tor-pubkey "descriptor:x25519:NWJNEFU487H2BI3JFNKJENFKJWI3"

    SSH:
    ----
    --ssh-key : key for automated SSH logins to standup non-privileged account.
    --sys-ssh-ip : Comma separated list of IPs that can use SSH.

*DISCLAIMER: It is always better to let your node validate blocks from the beginning. This script uses blockchain data signed by BTCPay Server. Trust at your own risk.

2. Environment Variables:
-------------------------

    # system
    --------
    NOPROMPT=true/false, set it to install the setup without prompting for confirmation.
    # START=true/false, start bitcoind & lightning after installation. Default: true.
    STARTUP_REGISTER=true/false, Do not set Bitcoind & Lightning to start after reboot. Default: true.
    SYSTEMD_RELOAD=true/false, Do not set Bitcoind & Lightning to start after crash. Default: true.
    VPS=true/false, set it to true if setting up on a VPS. Default: false.
    USERPASSWORD="", set password for user standup. Default: empty.

    #vps
    ----
    FQDN="", enter your fully qualified hostname. Example: my-awesome-node.my-awesome-domain.com
    HOSTNAME="", enter your hostname. Example: my-awesome-node.
    REGION="", enter your server's timezone location. Example Asia/Singapore.

    # bitcoind
    ----------
    NETFORK="mainnet", "testnet" or "regtest", Bitcoin network to use. Default: "mainnet".
    PRUNE="", Integer value to specify level of prune node.  Minimum value is 550. Default: empty(0).
    FASTSYNC=true/false, If you want to speed up the Initial Block Download then set it to true. Default: false.
    HWI=true/false, Choose to install HWI. Default: true.

    # lightning
    -----------
    LIGHTNING="c-lightning"/"lnd", choose lightning network implementation. Default: "c-lightning".

    # services
    ----------
    ESPLORA=true/false, Choose to install Esplora. Default: false.
    BTCPAYSERVER=true/false, Choose to install BTCPay Server. Default: false.
    # Tor
    TOR_PUBKEY="<string>" Tor Public Key. Default: empty.

    # ssh
    SSH_KEY="" key for automated SSH logins to standup non-privileged account. Default: empty.
    SYS_SSH_IP="" comma separated list of IPs that can use SSH. Default: empty.

----------------

END
}

####
# Environment Variables
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
  return
fi

echo "$0 - Logged in as root. Continuing with installation."
echo "----------------
"
# Output stdout and stderr to ~root files
exec > >(tee -a /root/standup.log) 2> >(tee -a /root/standup.log /root/standup.err >&2)


####
# Parsing Arguments
####
PARAMS=""

while (( "$#" ))
do
key="$1"
  case $key in
    -h|--help)
      help
      return
      ;;
    -y)
      NOPROMPT=true
      shift 1
      ;;
    --no-startup-register)
      STARTUP_REGISTER=false
      shift 1
      ;;
    --no-systemd-reload)
      SYSTEMD_RELOAD=false
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
      if [ ${2:0:1} == "-" ]
      then
        echo "Network flag passed without value. Installing default network: mainnet."
      shift 1
      elif [[ -n "$2" ]] && [[ "$2" == "mainnet" ]] || [[ "$2" == "testnet" ]] || [[ "$2" == "regtest" ]]
      then
        NETWORK="$2"
      else
        echo "ERROR: Network has to be either mainnet, testnet or regtest. Passed $2"
        return
      fi
      shift 1
      shift 1
      ;;
    -p|--prune)
      if [ ${2:0:1} == "-" ]
      then
        echo "Prune flag passed without value. Installing default: unpruned node."
      shift 1
      elif [[ -n "$2" ]] && [[ "$2" -ge 550 ]]
      then
        PRUNE="$2"
      else
        echo "ERROR: Minimum prune value is 550. Passed $2"
        return
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
      if [ ${2:0:1} == "-" ]
      then
        echo "Lightning flag passed without specifying the implementation. Installing default implementation: c-lightning"
      shift 1
      elif [[ -n "$2" ]] && [[ "$2" == "c-lightning" ]] || [[ "$2" == "lnd" ]]
      then
        LIGHTNING="$2"
      else
        echo "ERROR: Invalid lightning implementation. Pass c-lightning or lnd. Passed $2"
        return
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
      return
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift 1
      ;;
  esac
done
set -- "$PARAMS"  # set positional parameters in order

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

# prompt user before continuing with installation
if ! "$NOPROMPT"
then
  read -p "Continue with installation? (Y/n): " confirm
fi

if [[ "$confirm" != [yY] ]]
then
  echo "Entered $confirm. Exiting.."
  return
else
  NOPROMPT=true
  echo "Installing Bitcoin!"
fi



####
# 1. Update Hostname and set timezone
####


echo "
----------------"
echo "HOSTNAME: $HOSTNAME" > /etc/hostname
echo "----------------"
/bin/hostname $HOSTNAME

IPADDR=""
REGION=""

if $VPS
then
  # Set the variable $IPADDR to the IP address the new Linode receives.
  IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

  echo "$0 - Set hostname as $FQDN ($IPADDR)"
  echo "
  ***********************"
  echo "$0 - TODO: Put $FQDN with IP $IPADDR in your main DNS file."
  echo "***********************
  "
  echo "$0 - Set Time Zone to $REGION"
  echo $REGION > /etc/timezone
  cp /usr/share/zoneinfo/${REGION} /etc/localtime

  echo "Hostname, IP address and timezon are set. Put $FQDN with IP $IPADDR in your main DNS file."
fi

# Add localhost aliases

echo "127.0.0.1    localhost" > /etc/hosts
echo "127.0.1.1 $FQDN $HOSTNAME" >> /etc/hosts

echo "$0 - Set localhost"


####
# 2. Update Debian, Set autoupdate and Install UFW
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

# Install haveged (a random number generator)

if [ -z $(which haveged) ]
then
  echo "
----------------
  "
  echo "$0 - Installing haveged (a random number generator)"
  echo "
----------------
  "
  apt-get install haveged -y
echo "
----------------
"
echo "$0 - haveged installed successfully"
echo "
----------------
"
else
  echo "
  ----------------haveged already installed"
fi

# Set system to automatically update
echo "
----------------
"
echo "$0 - setting system to automatically update"
echo "
----------------
"
echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true" | debconf-set-selections
apt-get -y install unattended-upgrades
echo "
----------------
"
echo "$0 - Updated Debian Packages"
echo "
----------------
"
# Get uncomplicated firewall and deny all incoming connections except SSH
if [ -z $(which ufw) ]
then
  echo "
----------------
  "
  echo "$0 - Installing ufw"
  echo "
----------------
  "
  apt-get install ufw
fi

ufw allow ssh
ufw enable

echo "
----------------
"
echo "$0 - ufw is installed and enabled."
echo "
----------------
"

# Get GPG if not installed to verify signatures

if [ -z $(which gpg) ]
then
  echo "
----------------
  "
  echo "$0 - Installing gnupg2"
  echo "
----------------
  "
  apt-get install gnupg2 -y
  echo "
----------------
  "
  echo "Gnupg2 not found and installed"
  echo "
----------------
  "
fi

####
# 3. Create user admin
####

if [ -z $(cat /etc/shadow | grep standup) ] && [ -z $(groups standup) ]
then
  echo "
----------------
  "
  echo "Creating user standup"
  echo "
----------------
  "
  # Create "standup" user with optional password and give them sudo capability
  /usr/sbin/useradd -m -p `perl -e 'printf("%s\n",crypt($ARGV[0],"password"))' "$USERPASSWORD"` -g sudo -s /bin/bash standup
  /usr/sbin/adduser standup sudo

  echo "
----------------
  "
  echo "$0 - User standup created with sudo access."
  echo "
----------------
  "
else
  echo "----------------"
  echo "User standup already exists."
  echo "----------------"
fi

# Setup SSH Key if the user added one as an argument
if [ -n "$SSH_KEY" ]
then
  mkdir ~standup/.ssh
  echo "$SSH_KEY" >> ~standup/.ssh/authorized_keys
  chown -R standup ~standup/.ssh
  echo "
----------------
  "
  echo "$0 - Added .ssh key to standup."
  echo "
----------------
  "
fi

# Setup SSH allowed IP's if the user added any as an argument
if [ -n "$SYS_SSH_IP" ]
then
  echo "sshd: $SYS_SSH_IP" >> /etc/hosts.allow
  echo "sshd: ALL" >> /etc/hosts.deny
  echo "
----------------
  "
  echo "$0 - Limited SSH access."
  echo "
----------------
  "
else
  echo "
  ****************
  "
  echo "$0 - WARNING: Your SSH access is not limited; this is a major security hole!"
  echo "
  ****************
  "
fi


####
# 4. Install latest stable tor
####

# Download tor
echo "
----------------
"
echo "Installing Tor"
echo "
----------------
"
#  To use source lines with https:// in /etc/apt/sources.list the apt-transport-https package is required. Install it with:
if ! [ -z $(which apt-transport-https) ]
then
  apt-get install apt-transport-https
fi

# We need to set up our package repository before you can fetch Tor. First, you need to figure out the name of your distribution:
DEBIAN_VERSION=$(lsb_release -c | awk '{ print $2 }')

# You need to add the following entries to /etc/apt/sources.list:
cat >> /etc/apt/sources.list << EOF
deb https://deb.torproject.org/torproject.org $DEBIAN_VERSION main
deb-src https://deb.torproject.org/torproject.org $DEBIAN_VERSION main
EOF

# Then add the gpg key used to sign the packages by running:
apt-key adv --recv-keys --keyserver keys.gnupg.net  74A941BA219EC810
wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import
sudo gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

# Update system, install and run tor as a service
apt-get update
apt-get install tor deb.torproject.org-keyring

# Setup hidden service
sed -i -e 's/#ControlPort 9051/ControlPort 9051/g' /etc/tor/torrc
sed -i -e 's/#CookieAuthentication 1/CookieAuthentication 1/g' /etc/tor/torrc
sed -i -e 's/## address y:z./## address y:z.\
\
HiddenServiceDir \/var\/lib\/tor\/standup\/\
HiddenServiceVersion 3\
HiddenServicePort 1309 127.0.0.1:18332\
HiddenServicePort 1309 127.0.0.1:18443\
HiddenServicePort 1309 127.0.0.1:8332/g' /etc/tor/torrc
mkdir /var/lib/tor/standup
chown -R debian-tor:debian-tor /var/lib/tor/standup
chmod 700 /var/lib/tor/standup

# Add standup to the tor group so that the tor authentication cookie can be read by bitcoind
sudo usermod -a -G debian-tor standup

# Restart tor to create the HiddenServiceDir
sudo systemctl restart tor.service


# add V3 authorized_clients public key if one exists
if ! [ "$TOR_PUBKEY" == "" ]
then
  # create the directory manually incase tor.service did not restart quickly enough
  mkdir /var/lib/tor/standup/authorized_clients

  # need to assign the owner
  chown -R debian-tor:debian-tor /var/lib/tor/standup/authorized_clients

  # Create the file for the pubkey
  sudo touch /var/lib/tor/standup/authorized_clients/fullynoded.auth

  # Write the pubkey to the file
  sudo echo "$TOR_PUBKEY" > /var/lib/tor/standup/authorized_clients/fullynoded.auth

  # Restart tor for authentication to take effect
  sudo systemctl restart tor.service

  echo "$0 - Successfully added Tor V3 authentication"

else
  echo "$0 - No Tor V3 authentication, anyone who gets access to your QR code can have full access to your node, ensure you do not store more then you are willing to lose and better yet use the node as a watch-only wallet"
fi


####
# 5. Install Bitcoin
####

echo "
----------------
"
echo "Installing Bitcoin"
echo "
----------------
"
# Download Bitcoin
echo "$0 - Downloading Bitcoin; this will take a while!"

# CURRENT BITCOIN RELEASE:
# Change as necessary
export BITCOIN="bitcoin-core-0.20.0"
export BITCOINPLAIN=`echo $BITCOIN | sed 's/bitcoin-core/bitcoin/'`

sudo -u standup wget https://bitcoincore.org/bin/$BITCOIN/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz -O ~standup/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz
sudo -u standup wget https://bitcoincore.org/bin/$BITCOIN/SHA256SUMS.asc -O ~standup/SHA256SUMS.asc
sudo -u standup wget https://bitcoincore.org/laanwj-releases.asc -O ~standup/laanwj-releases.asc

# Verifying Bitcoin: Signature
echo "$0 - Verifying Bitcoin."

sudo -u standup /usr/bin/gpg --no-tty --import ~standup/laanwj-releases.asc
export SHASIG=`sudo -u standup /usr/bin/gpg --no-tty --verify ~standup/SHA256SUMS.asc 2>&1 | grep "Good signature"`
echo "SHASIG is $SHASIG"

if [[ $SHASIG ]]
then
  echo "$0 - VERIFICATION SUCCESS / SIG: $SHASIG"
else
  (>&2 echo "$0 - VERIFICATION ERROR: Signature for Bitcoin did not verify!")
fi

# Verify Bitcoin: SHA
export TARSHA256=`/usr/bin/sha256sum ~standup/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz | awk '{print $1}'`
export EXPECTEDSHA256=`cat ~standup/SHA256SUMS.asc | grep $BITCOINPLAIN-x86_64-linux-gnu.tar.gz | awk '{print $1}'`

if [ "$TARSHA256" == "$EXPECTEDSHA256" ]
then
  echo "$0 - VERIFICATION SUCCESS / SHA: $TARSHA256"
else
  (>&2 echo "$0 - VERIFICATION ERROR: SHA for Bitcoin did not match!")
fi

# Install Bitcoin
echo "$0 - Installing Bitcoin."

sudo -u standup /bin/tar xzf ~standup/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz -C ~standup
/usr/bin/install -m 0755 -o root -g root -t /usr/local/bin ~standup/$BITCOINPLAIN/bin/*
/bin/rm -rf ~standup/$BITCOINPLAIN/

# Start Up Bitcoin
echo "$0 - Configuring Bitcoin."

sudo -u standup /bin/mkdir ~standup/.bitcoin

# The only variation between Mainnet and Testnet is that Testnet has the "testnet=1" variable
# The only variation between Regular and Pruned is that Pruned has the "prune=550" variable, which is the smallest possible prune
RPCPASSWORD=$(xxd -l 16 -p /dev/urandom)

cat >> ~standup/.bitcoin/bitcoin.conf << EOF
server=1
prune=$PRUNE
rpcuser=StandUp
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
debug=tor
EOF

if [ -z "$PRUNE" ]
then
  cat >> ~standup/.bitcoin/bitcoin.conf << EOF
  txindex=1
EOF
fi

if [ "$NETWORK" == "testnet" ]
then
  cat >> ~standup/.bitcoin/bitcoin.conf << EOF
  testnet=1
EOF

elif [ "$NETWORK" == "regtest" ]
then
  cat >> ~standup/.bitcoin/bitcoin.conf << EOF
  regtest=1
EOF
fi

cat >> ~standup/.bitcoin/bitcoin.conf << EOF
[test]
rpcbind=127.0.0.1
rpcport=18332
[main]
rpcbind=127.0.0.1
rpcport=8332
[regtest]
rpcbind=127.0.0.1
rpcport=18443
EOF

/bin/chown standup ~standup/.bitcoin/bitcoin.conf
/bin/chmod 600 ~standup/.bitcoin/bitcoin.conf

# Setup bitcoind as a service that requires Tor
echo "$0 - Setting up Bitcoin as a systemd service."

sudo cat > /etc/systemd/system/bitcoind.service << EOF
# It is not recommended to modify this file in-place, because it will
# be overwritten during package upgrades. If you want to add further
# options or overwrite existing ones then use
# $ systemctl edit bitcoind.service
# See "man systemd.service" for details.
# Note that almost all daemon options could be specified in
# /etc/bitcoin/bitcoin.conf, except for those explicitly specified as arguments
# in ExecStart=
[Unit]
Description=Bitcoin daemon
After=tor.service
Requires=tor.service
[Service]
ExecStart=/usr/local/bin/bitcoind -conf=/home/standup/.bitcoin/bitcoin.conf
# Process management
####################
Type=simple
PIDFile=/run/bitcoind/bitcoind.pid
Restart=on-failure
# Directory creation and permissions
####################################
# Run as bitcoin:bitcoin
User=standup
Group=sudo
# /run/bitcoind
RuntimeDirectory=bitcoind
RuntimeDirectoryMode=0710
# Hardening measures
####################
# Provide a private /tmp and /var/tmp.
PrivateTmp=true
# Mount /usr, /boot/ and /etc read-only for the process.
ProtectSystem=full
# Disallow the process and all of its children to gain
# new privileges through execve().
NoNewPrivileges=true
# Use a new /dev namespace only populated with API pseudo devices
# such as /dev/null, /dev/zero and /dev/random.
PrivateDevices=true
# Deny the creation of writable and executable memory mappings.
MemoryDenyWriteExecute=true
[Install]
WantedBy=multi-user.target
EOF

echo "$0 - Starting bitcoind service"
sudo systemctl enable bitcoind.service
sudo systemctl start bitcoind.service

####
# 6. Install QR encoder and displayer, and show the btcstandup:// uri in plain text incase the QR Code does not display
####

# Get the Tor onion address for the QR code
HS_HOSTNAME=$(sudo cat /var/lib/tor/standup/hostname)

# Create the QR string
QR="btcstandup://StandUp:$RPCPASSWORD@$HS_HOSTNAME:1309/?label=StandUp.sh"

# Display the uri text incase QR code does not work
echo "$0 - **************************************************************************************************************"
echo "$0 - This is your btcstandup:// uri to convert into a QR which can be scanned with FullyNoded to connect remotely:"
echo $QR
echo "$0 - **************************************************************************************************************"
echo "$0 - Bitcoin is setup as a service and will automatically start if your VPS reboots and so is Tor"
echo "$0 - You can manually stop Bitcoin with: sudo systemctl stop bitcoind.service"
echo "$0 - You can manually start Bitcoin with: sudo systemctl start bitcoind.service"

# Finished, exit script
exit 0
