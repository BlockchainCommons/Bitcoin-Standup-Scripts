#!/bin/bash

#  Updated to install Bitcoin-Core 0.22.0 on 2021-09-21

# DISCLAIMER: It is not a good idea to store large amounts of Bitcoin on a VPS,
# ideally you should use this as a watch-only wallet. This script is expiramental
# and has not been widely tested. The creators are not responsible for loss of
# funds. If you are not familiar with running a node or how Bitcoin works then we
# urge you to use this in testnet so that you can use it as a learning tool.

# This script installs the latest stable version of Tor, Bitcoin Core,
# Uncomplicated Firewall (UFW), debian updates, enables automatic updates for
# debian for good security practices, installs a random number generator, and
# optionally a QR encoder and an image displayer.

# The script will display the uri in plain text which you can convert to a QR Code
# yourself. It is highly recommended to add a Tor V3 pubkey for cookie authentication
# so that even if your QR code is compromised an attacker would not be able to access
# your node.

# StandUp.sh sets Tor and Bitcoin Core up as systemd services so that they start
# automatically after crashes or reboots. By default it sets up a pruned testnet node,
# a Tor V3 hidden service controlling your rpcports and enables the firewall to only
# allow incoming connections for SSH. If you supply a SSH_KEY in the arguments
# it allows you to easily access your node via SSH using your rsa pubkey, if you add
# SYS_SSH_IP's your VPS will only accept SSH connections from those IP's.

# StandUp.sh will create a user called standup, and assign the optional password you
# give it in the arguments.

# StandUp.sh will create two logs in your root directory, to read them run:
# $ cat standup.err
# $ cat standup.log

####
#0. Prerequisites
####

# In order to run this script you need to be logged in as root, and enter in the commands
# listed below:

# (the $ represents a terminal commmand prompt, do not actually type in a $)

# First you need to give the root user a password:
# $ sudo passwd

# Then you need to switch to the root user:
# $ su - root

# Then create the file for the script:
# $ nano standup.sh

# Nano is a text editor that works in a terminal, you need to paste the entire contents
# of this script into your terminal after running the above command,
# then you can type:
# control x (this starts to exit nano)
# y (this confirms you want to save the file)
# return (just press enter to confirm you want to save and exit)

# Then we need to make sure the script can be executable with:
# $ chmod +x standup.sh

# After that you can run the script with the optional arguments like so:
# $ ./standup.sh "insert pubkey" "insert node type (see options below)" "insert ssh key" "insert ssh allowed IP's" "insert password for standup user"

####
# 1. Set Initial Variables from command line arguments
####

# The arguments are read as per the below variables:
# ./standup.sh "PUBKEY" "BTCTYPE" "SSH_KEY" "SYS_SSH_IP" "USERPASSWORD"

# If you want to omit an argument then input empty qoutes in its place for example:
# ./standup "" "Mainnet" "" "" "aPasswordForTheUser"

# If you do not want to add any arguments and run everything as per the defaults simply run:
# ./standup.sh

# To run Cypherpunk Pay:
# Set USE_CYPHERPUNKPAY="YES" before running standup.sh if you want to install CypherpunkPay
# Set CPPLITE='YES' before running standup.sh if you do not want to use a full node for CypherpunkPay. It will instead download blocks over Tor from randomised block explorers.
# Set CYPHERPUNKPAY_CAUSE to something like "Please help Satoshi fund his digital cash project!". This message will appear on your donation's page.
# Set XPUB to the mainnet xpub for your newly created wallet to receive Cypherpunkpay funds

# You can uncomment and edit the following lines:
# USE_CYPHERPUNKPAY="YES"
# CPPLITE="YES"
# CYPHERPUNKPAY_CAUSE="Donate to Us!"
# XPUB="xpub..."

# For Tor V3 client authentication (optional), you can run standup.sh like:
# ./standup.sh "descriptor:x25519:NWJNEFU487H2BI3JFNKJENFKJWI3"
# and it will automatically add the pubkey to the authorized_clients directory, which
# means the user is Tor authenticated before the node is even installed.
PUBKEY=$1

# Can be one of the following: "Mainnet", "Pruned Mainnet", "Testnet", "Pruned Testnet", or "Private Regtest", default is "Pruned Testnet"
BTCTYPE=$2

# Optional key for automated SSH logins to standup non-privileged account - if you do not want to add one add "" as an argument
SSH_KEY=$3

# Optional comma separated list of IPs that can use SSH - if you do not want to add any add "" as an argument
SYS_SSH_IP=$4

# Optional password for the standup non-privileged account - if you do not want to add one add "" as an argument
USERPASSWORD=$5

# Force check for root, if you are not logged in as root then the script will not execute
if ! [ "$(id -u)" = 0 ]
then

  echo "$0 - You need to be logged in as root!"
  exit 1

fi

# Output stdout and stderr to ~root files
exec > >(tee -a /standup.log) 2> >(tee -a /standup.log /standup.err >&2)

####
# 2. Bring Debian Up To Date
####

echo "$0 - Starting Debian updates; this will take a while!"

# Make sure all packages are up-to-date
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

# Install haveged (a random number generator)
apt-get install haveged -y

# Install GPG
apt-get install gnupg -y

# Install dirmngr
apt-get install dirmngr

# Set system to automatically update
echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true" | debconf-set-selections
apt-get -y install unattended-upgrades

echo "$0 - Updated Debian Packages"

# get uncomplicated firewall and deny all incoming connections except SSH
sudo apt-get install ufw
ufw allow ssh
ufw enable

####
# 3. Set Up User
####

# Create "standup" user with optional password and give them sudo capability
/usr/sbin/useradd -m -p `perl -e 'printf("%s\n",crypt($ARGV[0],"password"))' "$USERPASSWORD"` -g sudo -s /bin/bash standup
/usr/sbin/adduser standup sudo

echo "$0 - Setup standup with sudo access."

# Setup SSH Key if the user added one as an argument
if [ -n "$SSH_KEY" ]
then

   mkdir ~standup/.ssh
   echo "$SSH_KEY" >> ~standup/.ssh/authorized_keys
   chown -R standup ~standup/.ssh

   echo "$0 - Added .ssh key to standup."

fi

# Setup SSH allowed IP's if the user added any as an argument
if [ -n "$SYS_SSH_IP" ]
then

  echo "sshd: $SYS_SSH_IP" >> /etc/hosts.allow
  echo "sshd: ALL" >> /etc/hosts.deny
  echo "$0 - Limited SSH access."

else

  echo "$0 - WARNING: Your SSH access is not limited; this is a major security hole!"

fi

####
# 4. Install latest stable tor
####

# Download tor

#  To use source lines with https:// in /etc/apt/sources.list the apt-transport-https package is required. Install it with:
sudo apt install apt-transport-https

# We need to set up our package repository before you can fetch Tor. First, you need to figure out the name of your distribution:
DEBIAN_VERSION=$(lsb_release -c | awk '{ print $2 }')

# You need to add the following entries to /etc/apt/sources.list:
cat >> /etc/apt/sources.list << EOF
deb https://deb.torproject.org/torproject.org $DEBIAN_VERSION main
deb-src https://deb.torproject.org/torproject.org $DEBIAN_VERSION main
EOF

# Then add the gpg key used to sign the packages by running:
sudo apt-key adv --recv-keys --keyserver keys.gnupg.net  74A941BA219EC810
sudo wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import
sudo gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

# Update system, install and run tor as a service
sudo apt update
sudo apt install tor deb.torproject.org-keyring

# Setup hidden service

sed -i -e 's/#ControlPort 9051/ControlPort 9051/g' /etc/tor/torrc
sed -i -e 's/#CookieAuthentication 1/CookieAuthentication 1/g' /etc/tor/torrc

cat >> /etc/tor/torrc << EOF
HiddenServiceDir /var/lib/tor/bitcoin/mainnet/
HiddenServiceVersion 3
HiddenServicePort 8332 127.0.0.1:8332

HiddenServiceDir /var/lib/tor/bitcoin/testnet/
HiddenServiceVersion 3
HiddenServicePort 18332 127.0.0.1:18332

HiddenServiceDir /var/lib/tor/bitcoin/regtest/
HiddenServiceVersion 3
HiddenServicePort 18443 127.0.0.1:18443

HiddenServiceDir /var/lib/tor/lightning/
HiddenServiceVersion 3
HiddenServicePort 8080 127.0.0.1:8080

HiddenServiceDir /var/lib/tor/cypherpunkpay
HiddenServiceVersion 3
HiddenServicePort 8081 127.0.0.1:8081
EOF

mkdir /var/lib/tor/bitcoin
chown -R debian-tor:debian-tor /var/lib/tor/bitcoin
chmod 700 /var/lib/tor/bitcoin

mkdir /var/lib/tor/bitcoin/mainnet
chown -R debian-tor:debian-tor /var/lib/tor/bitcoin/mainnet
chmod 700 /var/lib/tor/bitcoin/mainnet

mkdir /var/lib/tor/bitcoin/testnet
chown -R debian-tor:debian-tor /var/lib/tor/bitcoin/testnet
chmod 700 /var/lib/tor/bitcoin/testnet

mkdir /var/lib/tor/bitcoin/regtest
chown -R debian-tor:debian-tor /var/lib/tor/bitcoin/regtest
chmod 700 /var/lib/tor/bitcoin/regtest

mkdir /var/lib/tor/lightning
chown -R debian-tor:debian-tor /var/lib/tor/lightning
chmod 700 /var/lib/tor/lightning

# Add standup to the tor group so that the tor authentication cookie can be read by bitcoind
sudo usermod -a -G debian-tor standup

# Restart tor to create the HiddenServiceDir
sudo systemctl restart tor.service


# add V3 authorized_clients public key if one exists
if ! [ "$PUBKEY" == "" ]
then

  # create the directory manually incase tor.service did not restart quickly enough
  mkdir /var/lib/tor/standup/authorized_clients

  # need to assign the owner
  chown -R debian-tor:debian-tor /var/lib/tor/standup/authorized_clients

  # Create the file for the pubkey
  sudo touch /var/lib/tor/standup/authorized_clients/fullynoded.auth

  # Write the pubkey to the file
  sudo echo "$PUBKEY" > /var/lib/tor/standup/authorized_clients/fullynoded.auth

  # Restart tor for authentication to take effect
  sudo systemctl restart tor.service

  echo "$0 - Successfully added Tor V3 authentication"

else

  echo "$0 - No Tor V3 authentication, anyone who gets access to your QR code can have full access to your node, ensure you do not store more then you are willing to lose and better yet use the node as a watch-only wallet"

fi

####
# 5. Install Bitcoin
####

# Download Bitcoin
echo "$0 - Downloading Bitcoin; this will also take a while!"

# CURRENT BITCOIN RELEASE:
# Change as necessary
export BITCOIN="bitcoin-core-23.0"
export BITCOINPLAIN=`echo $BITCOIN | sed 's/bitcoin-core/bitcoin/'`

sudo -u standup mkdir ~standup/.logs

sudo -u standup wget https://bitcoincore.org/bin/$BITCOIN/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz -O ~standup/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz -a ~standup/.logs/wget
sudo -u standup wget https://bitcoincore.org/bin/$BITCOIN/SHA256SUMS.asc -O ~standup/SHA256SUMS.asc -a ~standup/.logs/wget
sudo -u standup wget https://bitcoincore.org/bin/$BITCOIN/SHA256SUMS -O ~standup/SHA256SUMS -a ~standup/.logs/wget

sudo -u standup wget https://raw.githubusercontent.com/bitcoin/bitcoin/23.x/contrib/builder-keys/keys.txt -O ~standup/keys.txt -a ~standup/.logs/wget
sudo -u standup  sh -c 'while read fingerprint keyholder_name; do gpg --keyserver hkps://keys.openpgp.org --recv-keys ${fingerprint}; done < ~standup/keys.txt'

cat ~standup/.logs/wget >> /standup.log
cat ~standup/.logs/wget >> /standup.err
rm -r ~standup/.logs

# Verifying Bitcoin: Signature
echo "$0 - Verifying Bitcoin."

export SHASIG=`sudo -u standup /usr/bin/gpg --verify ~standup/SHA256SUMS.asc ~standup/SHA256SUMS 2>&1 | grep "Good signature"`
export SHACOUNT=`sudo -u standup /usr/bin/gpg --verify ~standup/SHA256SUMS.asc ~standup/SHA256SUMS 2>&1 | grep "Good signature" | wc -l`

if [[ "$SHASIG" ]]
then

    echo "$0 - SIG VERIFICATION SUCCESS: $SHACOUNT GOOD SIGNATURES FOUND."
    echo "$SHASIG"

else

    (>&2 echo "$0 - SIG VERIFICATION ERROR: No verified signatures for Bitcoin!")

fi

# Verify Bitcoin: SHA
export SHACHECK=`sudo -u standup sh -c 'cd ~standup; /usr/bin/sha256sum -c --ignore-missing < ~standup/SHA256SUMS 2>&1 | grep "OK"'`

if [ "$SHACHECK" ]
then

   echo "$0 - SHA VERIFICATION SUCCESS / SHA: $SHACHECK"

else

    (>&2 echo "$0 - SHA VERIFICATION ERROR: SHA for Bitcoin did not match!")

fi

# Install Bitcoin
echo "$0 - Installing Bitcoin."

sudo -u standup /bin/tar xzf ~standup/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz -C ~standup
/usr/bin/install -m 0755 -o root -g root -t /usr/local/bin ~standup/$BITCOINPLAIN/bin/*

# Copy man pages.
dest='/usr/local/share/man'
if [[ ! -d $dest ]]
then
    mkdir -p $dest
fi

cp -r ~standup/$BITCOINPLAIN/share/man/man1 /usr/local/share/man
command -v mandb && mandb 

/bin/rm -rf ~standup/$BITCOINPLAIN/

# Start Up Bitcoin
echo "$0 - Configuring Bitcoin."

sudo -u standup /bin/mkdir ~standup/.bitcoin

# The only variation between Mainnet and Testnet is that Testnet has the "testnet=1" variable
# The only variation between Regular and Pruned is that Pruned has the "prune=550" variable, which is the smallest possible prune
RPCPASSWORD=$(xxd -l 16 -p /dev/urandom)

cat >> ~standup/.bitcoin/bitcoin.conf << EOF
server=1
rpcuser=StandUp
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
debug=tor
EOF

if [ "$BTCTYPE" == "" ]; then

BTCTYPE="Pruned Testnet"

fi

if [ "$BTCTYPE" == "Mainnet" ]; then

cat >> ~standup/.bitcoin/bitcoin.conf << EOF
txindex=1
EOF

elif [ "$BTCTYPE" == "Pruned Mainnet" ]; then

cat >> ~standup/.bitcoin/bitcoin.conf << EOF
prune=550
EOF

elif [ "$BTCTYPE" == "Testnet" ]; then

cat >> ~standup/.bitcoin/bitcoin.conf << EOF
txindex=1
testnet=1
EOF

elif [ "$BTCTYPE" == "Pruned Testnet" ]; then

cat >> ~standup/.bitcoin/bitcoin.conf << EOF
prune=550
testnet=1
EOF

elif [ "$BTCTYPE" == "Private Regtest" ]; then

cat >> ~standup/.bitcoin/bitcoin.conf << EOF
regtest=1
txindex=1
EOF

else

  (>&2 echo "$0 - ERROR: Somehow you managed to select no Bitcoin Installation Type, so Bitcoin hasn't been properly setup. Whoops!")
  exit 1

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
HS_HOSTNAME=$(sudo cat /var/lib/tor/bitcoin/testnet/hostname)

# Create the QR string
QR="btcstandup://StandUp:$RPCPASSWORD@$HS_HOSTNAME:18332/?label=CLightningNode2"

# Get software packages for encoding a QR code and displaying it in a terminal
sudo apt-get install qrencode -y

/# Create the QR
sudo qrencode -m 10 -o /qrcode.png "$QR"

echo $QR | sudo tee -a /standup.uri

# Display the uri text incase QR code does not work
echo "$0 - **************************************************************************************************************"
echo "$0 - This is your btcstandup:// uri to convert into a QR which can be scanned with FullyNoded to connect remotely:"
echo $QR
echo "$0 - **************************************************************************************************************"
echo "$0 - Bitcoin is setup as a service and will automatically start if your VPS reboots and so is Tor"
echo "$0 - You can manually stop Bitcoin with: sudo systemctl stop bitcoind.service"
echo "$0 - You can manually start Bitcoin with: sudo systemctl start bitcoind.service"

# Install CypherpunkPay
# Ref. https://cypherpunkpay.org/installation/quick-start/

USE_NODE='true'
if [[ "$CPPLITE" == 'YES' ]]
then
    USE_NODE='false'
fi

if [[ "$USE_CYPHERPUNKPAY" == "YES" ]]
then

    echo "$0 - Bonus: Installing Cypherpunkpay"
    wget -qO - https://deb.cypherpunkpay.org/cypherpunkpay-package-signer.asc | sudo apt-key add -

    echo 'deb [arch=amd64] https://deb.cypherpunkpay.org/apt/ubuntu/ focal main' | sudo tee /etc/apt/sources.list.d/cypherpunkpay.list

    sudo apt-get update -y && sudo apt-get install -y cypherpunkpay

    echo "$0 - Editing Cypherpunkpay Config"
    sed -i -e  "s/listen = 127.0.0.1:8080/listen = 127.0.0.1:8081/;
                s/btc_network = testnet/btc_network = mainnet/;
                s/# btc_mainnet_account_xpub = REPLACE_ME_WITH_BTC_MAINNET_ACCOUNT_XPUB/btc_mainnet_account_xpub = $XPUB/;
                s/btc_mainnet_node_enabled = false/btc_mainnet_node_enabled = $USE_NODE/;
                s/btc_mainnet_node_rpc_user = bitcoin/btc_mainnet_node_rpc_user = StandUp/;
                s/btc_mainnet_node_rpc_password = secret/btc_mainnet_node_rpc_password = $RPCPASSWORD/;
                s/use_tor = false/use_tor = true/;
                s/donations_cause =.*$/donations_cause = $CYPHERPUNKPAY_CAUSE/" /etc/cypherpunkpay.conf

    sudo systemctl enable cypherpunkpay
    sudo systemctl start cypherpunkpay
fi

# Finished, exit script
exit 1
