#!/bin/bash

# standup script - bitcoin installation

####
# 5. Install Bitcoin
####

echo ""
echo "----------------"
echo "Installing Bitcoin"
echo "----------------"
echo ""
# Download Bitcoin

# CURRENT BITCOIN RELEASE:
# Change as necessary
export BITCOIN="bitcoin-core-0.20.0"
export BITCOINPLAIN=`echo $BITCOIN | sed 's/bitcoin-core/bitcoin/'`

# # get bitcoin tar.gz, shasums and signing keys
# clearnet
# sudo -u standup wget https://bitcoincore.org/bin/$BITCOIN/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz -O ~standup/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz
# sudo -u standup wget https://bitcoincore.org/bin/$BITCOIN/SHA256SUMS.asc -O ~standup/SHA256SUMS.asc

# onionnet
# If the script fails to download bitcoin-core using the onion link then the onion link might have changed. Check for the updated link here: https://bitcoincore.org/en/2020/03/27/hidden-service/
# OR alternatively uncomment the clearnet links to download bitcoin over clearnet.
if ! [[ -f ~standup/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz ]]
then
  echo ""
  echo "-----------"
  echo "Downloading $BITCOIN, this will take a while!"
  echo "-----------"
  echo ""
sudo -u standup torsocks wget --progress=bar:force http://6hasakffvppilxgehrswmffqurlcjjjhd76jgvaqmsg6ul25s7t3rzyd.onion/bin/"$BITCOIN"/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz -O ~standup/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz
fi

if [[ -f ~standup/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz ]] && ! [[ -f ~standup/SHA256SUMS.asc ]]
then
  echo "--------------StandUp - $BITCOINPLAIN-x86_64-linux-gnu.tar.gz exists at /home/standup/"
  echo ""
  echo "----StandUp - downloading SHA256SUMS.asc for $BITCOIN"
  echo ""
sudo -u standup torsocks wget http://6hasakffvppilxgehrswmffqurlcjjjhd76jgvaqmsg6ul25s7t3rzyd.onion/bin/"$BITCOIN"/SHA256SUMS.asc -O ~standup/SHA256SUMS.asc
else
  return 100
fi

if [[ -f ~standup/SHA256SUMS.asc ]]
then
  echo "----------StandUp - SHA256SSUMS.asc exists at /home/standup/"
fi

if ! [[ -f ~standup/laanwj-releases.asc ]]
then
  echo "-----StandUp - downloading laanwj-release signature"
sudo -u standup wget https://bitcoin.org/laanwj-releases.asc -O ~standup/laanwj-releases.asc
fi

# Verifying Bitcoin: Signature
echo ""
echo "-----------------"
echo "StandUp - Verifying Bitcoin."
echo "-----------------"
echo ""

sudo -u standup /usr/bin/gpg --no-tty --import ~standup/laanwj-releases.asc
export BTC_SHASIG=`sudo -u standup /usr/bin/gpg --no-tty --verify ~standup/SHA256SUMS.asc 2>&1 | grep "Good signature"`
echo ""
echo "---------BTC_SHASIG is $BTC_SHASIG"
echo ""

if [[ $BTC_SHASIG ]]
then
  echo ""
  echo "------StandUp - VERIFICATION SUCCESS / SIG: $BTC_SHASIG"
  echo ""
else
  (>&2 echo "
  ------------StandUp - VERIFICATION ERROR: Signature for Bitcoin did not verify!
  ")
  return 101
fi

# Verify Bitcoin: SHA
export BTC_TARSHA256=`/usr/bin/sha256sum ~standup/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz | awk '{print $1}'`
export BTC_EXPECTEDSHA256=`cat ~standup/SHA256SUMS.asc | grep "$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz | awk '{print $1}'`

if [[ "$BTC_TARSHA256" = "$BTC_EXPECTEDSHA256" ]]
then
  echo ""
  echo "------StandUp - VERIFICATION SUCCESS / SHA: $BTC_TARSHA256"
  echo ""
else
  (>&2 echo "
  -----------StandUp - VERIFICATION ERROR: SHA for Bitcoin did not match!
  ")
  return 102
fi

# Install Bitcoin
echo "--------------"
echo ""
echo "StandUp - Installing Bitcoin."
echo ""
echo "--------------"
echo ""

sudo -u standup /bin/tar xzf ~standup/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz -C ~standup
/usr/bin/install -m 0755 -o root -g root -t /usr/local/bin ~standup/"$BITCOINPLAIN"/bin/*
/bin/rm -rf ~standup/"$BITCOINPLAIN"/

# Start Up Bitcoin
echo ""
echo "------StandUp - Configuring Bitcoin."
echo ""

sudo -u standup /bin/mkdir ~standup/.bitcoin

RPCPASSWORD=$(xxd -l 16 -p /dev/urandom)

if [[ "$PRUNE" -eq 0 ]]
then
  PRUNE=""
fi

cat >> ~standup/.bitcoin/bitcoin.conf << EOF
# launches bitcoind as server to accept rpc connections
server=1

debug=tor

# prune
prune=$PRUNE

# rpc credentials
rpcuser=StandUp
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1

# zmq
zmqpubrawblock=tcp://127.0.0.1:28332
zmqpubrawtx=tcp://127.0.0.1:28333
EOF

if [[ -z "$PRUNE" ]]
then
  cat >> ~standup/.bitcoin/bitcoin.conf << EOF
  txindex=1
EOF
fi

# you are adding anything to the config file then add before this block else, the settings will only be affected in the specified network block.
# conversely, add settings specific to a particular network in their respective blocks.
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
echo ""
echo "-------StandUp - Setting up Bitcoin as a systemd service."
echo ""

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

echo ""
echo "-------StandUp - Starting bitcoind service"
echo ""

sudo systemctl enable bitcoind.service
sudo systemctl start bitcoind.service

####
# 6. Install QR encoder and displayer, and show the btcstandup:// uri in plain text incase the QR Code does not display
####
if [[ $(systemctl status bitcoind | grep active | awk '{print $2}') = "active" ]]
then
  # Get the Tor onion address for the QR code
  HS_HOSTNAME=$(sudo cat /var/lib/tor/standup/hostname)

  # Create the QR string
  QR="btcstandup://StandUp:"$RPCPASSWORD"@"$HS_HOSTNAME":1309/?label=StandUp.sh"

  # Display the uri text incase QR code does not work
  echo "StandUp - **************************************************************************************************************"
  echo "StandUp - This is your btcstandup:// uri to convert into a QR which can be scanned with FullyNoded to connect remotely:"
  echo "$QR"
  echo "StandUp - **************************************************************************************************************"
  echo ""
  echo "StandUp - Bitcoin is setup as a service and will automatically start if your VPS reboots and so is Tor"
  echo ""
  echo ""
  echo "StandUp - You can manually stop Bitcoin with: sudo systemctl stop bitcoind.service"
  echo ""
  echo ""
  echo "StandUp - You can manually start Bitcoin with: sudo systemctl start bitcoind.service"
  echo ""
else
  echo ""
  echo "ERROR: Bitcoind service not running hence QR code or URI  not generated. Exiting."
  echo ""
fi
