#!/bin/bash

# standup script - bitcoin installation

####
# 5. Install Bitcoin
####

echo "
----------------"
echo "Installing Bitcoin"
echo "----------------
"
# Download Bitcoin

# CURRENT BITCOIN RELEASE:
# Change as necessary
export BITCOIN="bitcoin-core-0.20.0"
export BITCOINPLAIN=`echo $BITCOIN | sed 's/bitcoin-core/bitcoin/'`

# # get bitcoin tar.gz, shasums and signing keys
# clearnet
# sudo -u standup wget https://bitcoincore.org/bin/$BITCOIN/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz -O ~standup/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz
# sudo -u standup wget https://bitcoincore.org/bin/$BITCOIN/SHA256SUMS.asc -O ~standup/SHA256SUMS.asc
# sudo -u standup wget https://bitcoin.org/laanwj-releases.asc -O ~standup/laanwj-releases.asc

# tor
# tar: http://6hasakffvppilxgehrswmffqurlcjjjhd76jgvaqmsg6ul25s7t3rzyd.onion/bin/bitcoin-core-0.20.0/bitcoin-0.20.0-x86_64-linux-gnu.tar.gz

if ! [ -f ~standup/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz ]
then
  echo "
  -----------
  Downloading $BITCOIN, this will take a while!
-----------
"
sudo -u standup torsocks wget http://6hasakffvppilxgehrswmffqurlcjjjhd76jgvaqmsg6ul25s7t3rzyd.onion/bin/$BITCOIN/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz -O ~standup/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz
fi

if [[ -f ~standup/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz ]] && ! [[ -f ~standup/SHA256SUMS.asc ]]
then
  echo "--------------$0 - $BITCOINPLAIN-x86_64-linux-gnu.tar.gz exists at /home/standup/
  "
  echo "----$0 - downloading SHA256SUMS.asc for $BITCOIN
#   "
sudo -u standup torsocks wget http://6hasakffvppilxgehrswmffqurlcjjjhd76jgvaqmsg6ul25s7t3rzyd.onion/bin/$BITCOIN/SHA256SUMS.asc -O ~standup/SHA256SUMS.asc
else
  return 100
fi

if [[ -f ~standup/SHA256SUMS.asc ]]
then
  echo "----------$0 - SHA256SSUMS.asc exists at /home/standup/"
fi

if ! [[ -f ~standup/laanwj-releases.asc ]]
then
  echo "-----$0 - downloading laanwj-release signature"
sudo -u standup wget https://bitcoin.org/laanwj-releases.asc -O ~standup/laanwj-releases.asc
fi

# 404
# sudo -u standup torsocks wget http://6hasakffvppilxgehrswmffqurlcjjjhd76jgvaqmsg6ul25s7t3rzyd.onion/laanwj-releases.asc -O ~standup/laanwj-releases.asc

# Verifying Bitcoin: Signature
echo "
-----------------
$0 - Verifying Bitcoin.
-----------------
"

sudo -u standup /usr/bin/gpg --no-tty --import ~standup/laanwj-releases.asc
export BTC_SHASIG=`sudo -u standup /usr/bin/gpg --no-tty --verify ~standup/SHA256SUMS.asc 2>&1 | grep "Good signature"`
echo "
---------SHASIG is $SHASIG
"

if [[ $BTC_SHASIG ]]
then
  echo "
  ------$0 - VERIFICATION SUCCESS / SIG: $BTC_SHASIG
  "
else
  (>&2 echo "
  ------------$0 - VERIFICATION ERROR: Signature for Bitcoin did not verify!
  ")
  return 101
fi

# Verify Bitcoin: SHA
export BTC_TARSHA256=`/usr/bin/sha256sum ~standup/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz | awk '{print $1}'`
export BTC_EXPECTEDSHA256=`cat ~standup/SHA256SUMS.asc | grep $BITCOINPLAIN-x86_64-linux-gnu.tar.gz | awk '{print $1}'`

if [ "$BTC_TARSHA256" == "$BTC_EXPECTEDSHA256" ]
then
  echo "
  ------$0 - VERIFICATION SUCCESS / SHA: $BTC_TARSHA256
  "
else
  (>&2 echo "
  -----------$0 - VERIFICATION ERROR: SHA for Bitcoin did not match!
  ")
  # return 102
fi

# Install Bitcoin
echo "--------------"
echo "
$0 - Installing Bitcoin.
"
echo "--------------
"

sudo -u standup /bin/tar xzf ~standup/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz -C ~standup
/usr/bin/install -m 0755 -o root -g root -t /usr/local/bin ~standup/$BITCOINPLAIN/bin/*
/bin/rm -rf ~standup/$BITCOINPLAIN/

# Start Up Bitcoin
echo "
------$0 - Configuring Bitcoin.
"

sudo -u standup /bin/mkdir ~standup/.bitcoin

# The only variation between Mainnet and Testnet is that Testnet has the "testnet=1" variable
# The only variation between Regular and Pruned is that Pruned has the "prune=550" variable, which is the smallest possible prune
RPCPASSWORD=$(xxd -l 16 -p /dev/urandom)

if [[ "$PRUNE" -eq 0 ]]
then
  $PRUNE = ""
fi

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
echo "
-------$0 - Setting up Bitcoin as a systemd service.
"

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

echo "
-------$0 - Starting bitcoind service
"
sudo systemctl enable bitcoind.service
sudo systemctl start bitcoind.service

####
# 6. Install QR encoder and displayer, and show the btcstandup:// uri in plain text incase the QR Code does not display
####
if [ "$(systemctl is-active --quiet bitcoind) | grep active" ]
then
  # Get the Tor onion address for the QR code
  HS_HOSTNAME=$(sudo cat /var/lib/tor/standup/hostname)

  # Create the QR string
  QR="btcstandup://StandUp:$RPCPASSWORD@$HS_HOSTNAME:1309/?label=StandUp.sh"

  # Display the uri text incase QR code does not work
  echo "$0 - **************************************************************************************************************"
  echo "$0 - This is your btcstandup:// uri to convert into a QR which can be scanned with FullyNoded to connect remotely:"
  echo $QR
  echo "$0 - **************************************************************************************************************"
  echo "
  $0 - Bitcoin is setup as a service and will automatically start if your VPS reboots and so is Tor
  "
  echo "
  $0 - You can manually stop Bitcoin with: sudo systemctl stop bitcoind.service
  "
  echo "
  $0 - You can manually start Bitcoin with: sudo systemctl start bitcoind.service
  "
else
  echo "
  ERROR: Bitcoind service not running hence QR code or URI  not generated. Exiting.
  "
fi
