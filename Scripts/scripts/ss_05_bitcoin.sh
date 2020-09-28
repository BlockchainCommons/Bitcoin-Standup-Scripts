#!/bin/bash

# standup script - bitcoin installation

####
# 5. Install Bitcoin
####

echo "

----------------
  $MESSAGE_PREFIX Installing Bitcoin
----------------
"
# Download Bitcoin

# CURRENT BITCOIN RELEASE:
# Change as necessary
export BITCOIN="bitcoin-core-0.20.1"
export BITCOINPLAIN=`echo $BITCOIN | sed 's/bitcoin-core/bitcoin/'`

# # get bitcoin tar.gz, shasums and signing keys
# clearnet
# sudo -u standup wget https://bitcoincore.org/bin/$BITCOIN/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz -O ~standup/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz
# sudo -u standup wget https://bitcoincore.org/bin/$BITCOIN/SHA256SUMS.asc -O ~standup/SHA256SUMS.asc

# onionnet
# If the script fails to download bitcoin-core using the onion link then the onion link might have changed. Check for the updated link here: https://bitcoincore.org/en/2020/03/27/hidden-service/
# OR alternatively uncomment the clearnet links to download bitcoin over clearnet.
if ! [[ -f ~standup/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz ]]; then
  echo "
----------------
$MESSAGE_PREFIX Downloading $BITCOIN, this will take a while!
----------------
  "

sudo -u standup torsocks wget --progress=bar:force http://6hasakffvppilxgehrswmffqurlcjjjhd76jgvaqmsg6ul25s7t3rzyd.onion/bin/"$BITCOIN"/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz -O ~standup/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz
fi

if [[ -f ~standup/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz ]] && ! [[ -f ~standup/SHA256SUMS.asc ]]; then
  echo "
$MESSAGE_PREFIX $BITCOINPLAIN-x86_64-linux-gnu.tar.gz exists at /home/standup/
  "
  echo "
$MESSAGE_PREFIX downloading SHA256SUMS.asc for $BITCOIN
  "
sudo -u standup torsocks wget http://6hasakffvppilxgehrswmffqurlcjjjhd76jgvaqmsg6ul25s7t3rzyd.onion/bin/"$BITCOIN"/SHA256SUMS.asc -O ~standup/SHA256SUMS.asc
else
  return 100
fi

if [[ -f ~standup/SHA256SUMS.asc ]]; then
  echo "
$MESSAGE_PREFIX SHA256SSUMS.asc exists at /home/standup/
"
fi

if ! [[ -f ~standup/laanwj-releases.asc ]]; then
  echo "
$MESSAGE_PREFIX downloading laanwj-release signature
"
sudo -u standup wget https://bitcoin.org/laanwj-releases.asc -O ~standup/laanwj-releases.asc
fi

# Verifying Bitcoin: Signature
echo "
-----------------
$MESSAGE_PREFIX Verifying Bitcoin.
-----------------
"

sudo -u standup /usr/bin/gpg --no-tty --import ~standup/laanwj-releases.asc
export BTC_SHASIG=`sudo -u standup /usr/bin/gpg --no-tty --verify ~standup/SHA256SUMS.asc 2>&1 | grep "Good signature" | awk '{print $2, $3}'`

if [[ $BTC_SHASIG ]]; then
  echo "
$MESSAGE_PREFIX VERIFICATION SUCCESS / SIG: $BTC_SHASIG
  "
else
  (>&2 echo "
  $MESSAGE_PREFIX VERIFICATION ERROR: Signature for Bitcoin did not verify!
  ")
  return 101
fi

# Verify Bitcoin: SHA
export BTC_TARSHA256=`/usr/bin/sha256sum ~standup/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz | awk '{print $1}'`
export BTC_EXPECTEDSHA256=`cat ~standup/SHA256SUMS.asc | grep "$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz | awk '{print $1}'`

if [[ "$BTC_TARSHA256" = "$BTC_EXPECTEDSHA256" ]]; then
  echo "
$MESSAGE_PREFIX VERIFICATION SUCCESS / SHA: $BTC_TARSHA256
  "
else
  (>&2 echo "
  $MESSAGE_PREFIX VERIFICATION ERROR: SHA for Bitcoin did not match!
  ")
  return 102
fi

# Install Bitcoin
sudo -u standup /bin/tar xzf ~standup/"$BITCOINPLAIN"-x86_64-linux-gnu.tar.gz -C ~standup
/usr/bin/install -m 0755 -o root -g root -t /usr/local/bin ~standup/"$BITCOINPLAIN"/bin/*
/bin/rm -rf ~standup/"$BITCOINPLAIN"/

# Start Up Bitcoin
echo "
$MESSAGE_PREFIX Configuring Bitcoin.
"

# create bitcoin data dir
mkdir $BTC_DATA_DIR/.bitcoin
FULL_BTC_DATA_DIR=$BTC_DATA_DIR/.bitcoin
chown standup $FULL_BTC_DATA_DIR
# create a symlink user standup's home directory.
if [[ "$BTC_DATA_DIR" != /home/standup ]]; then
  ln -s $FULL_BTC_DATA_DIR /home/standup/
fi

RPCPASSWORD=$(xxd -l 16 -p /dev/urandom)
RPCUSER="StandUp"

if [[ "$PRUNE" -eq 0 ]] || [[ "$PRUNE" == "__UNDEFINED__" ]]; then
  PRUNE=""
fi

# # FastSync implementation - WIP
# UTXO_MN_609375_SHA="52f0fc62dd28d016f49a75c22a6fa0827efc730f882bfa8cbc5ef96736d12100"
# UTXO_TN_1445586_SHA="eabaaa717bb8eeaf603e383dd8642d9d34df8e767fccbd208b0c936b79c82742"

# if "$FASTSYNC" && [[ "$NETWORK" == mainnet ]]; then
#   UTXO_DOWNLOAD_LINK="http://utxosets.blob.core.windows.net/public/utxo-snapshot-bitcoin-mainnet-609375.tar"
#   TAR_NAME="$(basename UTXO_DOWNLOAD_LINK)"
#   echo "
#   $MESSAGE_PREFIX downloading mainnet UTXO snapshot from BTCPay server
#   "
#   wget "$UTXO_DOWNLOAD_LINK" -q --show-progress
#   UTXO_DL_SHA="$(sha256sum $TAR_NAME)"
#   if [[ "$UTXO_MN_609375_SHA" != "$UTXO_DL_SHA" ]]; then
#     echo "
#     $MESSAGE_PREFIX the downloaded UTXO set failed SHA verification and is untrested, exiting.
#     "
#     return 103
#   else
#     tar -xf "$TAR_FILE" -C "$FULL_BTC_DATA_DIR"
#   fi
# elif "$FASTSYNC" && [[ "$NETWORK" == testnet ]]; then
#   UTXO_DOWNLOAD_LINK="http://utxosets.blob.core.windows.net/public/utxo-snapshot-bitcoin-testnet-1445586.tar"
#   TAR_NAME="$(basename UTXO_DOWNLOAD_LINK)"
#   echo "
#   $MESSAGE_PREFIX downloading testnet UTXO snapshot from BTCPay server
#   "
#   wget "$UTXO_DOWNLOAD_LINK" -q --show-progress
#   UTXO_DL_SHA="$(sha256sum $TAR_NAME)"
#   if [[ "$UTXO_MN_609375_SHA" != "$UTXO_DL_SHA" ]]; then
#     echo "
#     $MESSAGE_PREFIX the downloaded UTXO set failed SHA verification and is untrested, exiting.
#     "
#     return 103
#   else
#     tar -xf "$TAR_FILE" -C "$FULL_BTC_DATA_DIR/testnet3"
#   fi
# fi

cat >> $FULL_BTC_DATA_DIR/bitcoin.conf << EOF
# launches bitcoind as server to accept rpc connections
server=1
debug=tor

# Specify a non-default location to store blockchain and other data.
datadir=$FULL_BTC_DATA_DIR

# prune
prune=$PRUNE

# rpc credentials
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1

# zmq
zmqpubrawblock=tcp://127.0.0.1:28332
zmqpubrawtx=tcp://127.0.0.1:28333
EOF

if [[ -z "$PRUNE" ]] || [[ "$PRUNE" == "__UNDEFINED__" ]]; then
  cat >> $FULL_BTC_DATA_DIR/bitcoin.conf << EOF
  txindex=1
EOF
fi

# you are adding anything to the config file then add before this block else, the settings will only be affected in the specified network block.
# conversely, add settings specific to a particular network in their respective blocks.
cat >> $FULL_BTC_DATA_DIR/bitcoin.conf << EOF
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

/bin/chown standup $FULL_BTC_DATA_DIR/bitcoin.conf
/bin/chmod 740 $FULL_BTC_DATA_DIR/bitcoin.conf

# Setup bitcoind as a service that requires Tor
echo "
$MESSAGE_PREFIX Setting up Bitcoin as a systemd service.
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
Requires=tor.service
After=tor.service

[Service]
ExecStart=/usr/local/bin/bitcoind -conf=/home/standup/.bitcoin/bitcoin.conf

# Process management
####################
Type=simple
PIDFile=/run/bitcoind/bitcoind.pid
Restart=on-failure

# Directory creation and permissions
####################################
# Run as standup:standup
User=standup
Group=standup
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


# enable lightnind service
echo "
$MESSAGE_PREFIX Starting bitcoind service
"
sudo systemctl restart tor
sleep 4
sudo systemctl enable bitcoind.service
sudo systemctl start bitcoind.service

####
# 6. Install QR encoder and displayer, and show the btcstandup:// uri in plain text incase the QR Code does not display
####
if [[ $(systemctl status bitcoind | grep active | awk '{print $2}') = "active" ]]; then
  # Get the Tor onion address for the QR code
  HS_HOSTNAME="$(sudo cat /var/lib/tor/standup/bitcoin/hostname)"

  # Create the QR string
  QR="btcstandup://StandUp:"$RPCPASSWORD"@"$HS_HOSTNAME":1309/?label=StandUp.sh"

  # Display the uri text incase QR code does not work
  echo "
  ***********************************************************************************************************************"
  echo "StandUp - This is your btcstandup:// uri to convert into a QR which can be scanned with FullyNoded to connect remotely:"
  echo "$QR"
  echo "***********************************************************************************************************************
  "
  echo "
$MESSAGE_PREFIX Bitcoin is setup as a service and will automatically start if your VPS reboots and so is Tor
  "
  echo "
$MESSAGE_PREFIX You can manually stop Bitcoin with: sudo systemctl stop bitcoind
  "
  echo "
$MESSAGE_PREFIX You can manually start Bitcoin with: sudo systemctl start bitcoind
  "
  echo "
  $MESSAGE_PREFIX Your bitcoin data directory is:
  -----------------------------------------------
    $FULL_BTC_DATA_DIR
  -----------------------------------------------
  "
else
  echo "
ERROR: Bitcoind service not running hence QR code or URI  not generated. Exiting.
  "
fi
