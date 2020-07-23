#!/bin/bash

# standup script - install lnd

# check if bitcoind is running

# install Go
GO_VERSION="go1.14.4"
OS="linux"
ARCH="amd64"
GOSHA="aed845e4185a0b2a3c3d5e1d0a35491702c55889192bb9c30e67a3de6849c067"

## check & remove older go version
if [[ -n $(which go) ]]
then
  if [[ $(go version | awk '{print $3}') != "$GO_VERSION" ]]
  then
    rm -rf /usr/local/go
  fi
fi

## get go
sudo -u standup wget --progress=bar:force https://dl.google.com/go/"$GO_VERSION"."$OS"-"$ARCH".tar.gz -O ~standup/"$GO_VERSION"."$OS"-"$ARCH".tar.gz
GOTARSHA=$(sudo -u standup /usr/bin/sha256sum ~standup/"$GO_VERSION"."$OS"-"$ARCH".tar.gz | awk -F " " '{ print $1 }')

if [[ "$GOTARSHA" != "$GOSHA" ]]
then
  echo "
  ---------$0 - Go checksum validation failed. Exiting.
  "
  return 201
else
  echo "
  --------$0 - Go checksum validated. Continuing with installing LND.
  "
fi

# get go_sha from website to check
sudo -u standup /bin/tar xzf ~standup/"$GO_VERSION"."$OS"-"$ARCH".tar.gz -C ~standup
sudo mv ~standup/go /usr/local

export PATH="$PATH":/usr/local/go/bin:"$GOPATH"/bin
export GOPATH=~standup/gocode

# test go
if [[ $(go version | awk '{print $3}') = "$GO_VERSION" ]]
then
  echo "
  ----------$0 - $GO_VERSION successfully installed
  "
else
  echo "
  ----------$0 - Go not installed, cannot install lnd
  "
  return 202
fi

# build lnd
echo "
--------$0 - getting lnd... this will take a while!
"
go get -d github.com/lightningnetwork/lnd
cd "$GOPATH"/src/github.com/lightningnetwork/lnd
make
make install # installs to /home/standup/gocode/bin which is $GOPATH/bin

LND_VERSION=$(lnd --version)
echo "
-----------$0 - installed $LND_VERSION
"

sudo cp $GOPATH/bin/lnd $GOPATH/bin/lncli /usr/bin

# create symbolic link to bitcoin config
ln -s /etc/bitcoin/bitcoin.conf ~standup/.bitcoin/bitcoin.conf

# create config necessary directories
mkdir -p /etc/lnd

BTC_NETWORK=""
if [[ "$NETWORK" = "mainnet" ]]
then
  BTC_NETWORK="bitcoin.mainnet=1"
elif [[ "$NETWORK" = "testnet" ]]
then
  BTC_NETWORK="bitcoin.testnet=1"
else
  BTC_NETWORK="bitcoin.regtest=1"
fi

BITCOINDRPC_USER=$(cat ~standup/.bitcoin/bitcoin.conf | grep rpcuser | awk -F = '{print $2}')
BITCOINRPC_PASS=$(cat ~standup/.bitcoin/bitcoin.conf | grep rpcpassword | awk -F = '{print $2}')

# create lnd config
cat > /etc/lnd/lnd.conf << EOF
[Application Options]
datadir=/var/lib/lnd/data
tlscertpath=/var/lib/lnd/tls.cert
tlskeypath=/var/lib/lnd/tls.key
logdir=/var/lib/lnd/logs
maxlogfiles=3
maxlogfilesize=10
#externalip=1.1.1.1 # change to your public IP address if required.
alias=$LN_ALIAS
listen=0.0.0.0:9375
debuglevel=debug

[Bitcoin]
bitcoin.active=1
bitcoin.node=bitcoind
$BTC_NETWORK

#[Bitcoind]
#bitcoind.rpchost=localhost
#bitcoind.rpcuser=$BITCOINRPC_USER
#bitcoind.rpcpass=$BITCOINRPC_PASS
#bitcoind.zmqpubrawblock=tcp://127.0.0.1:28332
#bitcoind.zmqpubrawtx=tcp://127.0.0.1:28333

[tor]
tor.active=true
tor.v3=true
EOF

# set directories & appropriate permissions
mkdir -p /var/lib/lnd
chown standup:root -R /var/lib/lnd
chown standup:root -R /etc/lnd
chmod 644 /etc/lnd/lnd.conf

# create systemd service
cat > /etc/systemd/system/lnd.service << EOF
# It is not recommended to modify this file in-place, because it will
# be overwritten during package upgrades. If you want to add further
# options or overwrite existing ones then use
# $ systemctl edit lnd.service
# See "man systemd.service" for details.
# Note that almost all daemon options could be specified in
# /etc/lnd/lnd.conf, except for those explicitly specified as arguments
# in ExecStart=

[Unit]
Description=LND Lightning Network Daemon
Requires=bitcoind.service
After=bitcoind.service

[Service]
ExecStart=/usr/bin/lnd --configfile=/etc/lnd/lnd.conf
ExecStop=/usr/bin/lncli --lnddir /var/lib/lnd stop
PIDFile=/run/lnd/lnd.pid

User=standup
Group=standup

Type=simple
KillMode=process
TimeoutStartSec=60
TimeoutStopSec=60
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

ln -s /var/lib/lnd ~standup/.lnd


# [Unit]
# Description=LND Lightning Daemon
# Wants=bitcoind.service
# After=bitcoind.service

# # for use with sendmail alert
# #OnFailure=systemd-sendmail@%n

# [Service]
# EnvironmentFile=/run/publicip
# ExecStart=/usr/local/bin/lnd --sync-freelist --externalip=${PUBLICIP}:9736
# PIDFile=/home/bitcoin/.lnd/lnd.pid
# User=bitcoin
# Group=bitcoin
# LimitNOFILE=128000
# Type=simple
# KillMode=process
# TimeoutSec=180
# Restart=always
# RestartSec=60

# [Install]
# WantedBy=multi-user.target
# #

#enable lnd service
sudo systemctl enable lnd
sudo systemctl start lnd

# check if lnd running
echo "
-------$0 - Checking if LND is running
"
# waiting=3
# while [[ $(systemctl is-active lnd) != "active" ]] && [[ "$waiting" -gt 0 ]]
# do
# echo "waiting..."
sleep 10
# "$waiting"="$waiting" - 1
if [[ $(systemctl status lnd | grep active | awk '{print $2}') = "active" ]]; then
  echo "
  --------$0 - LND service now is active.
  "
  echo "
  -------$0 - chekcing LND and Tor..
  "
  LND_TOR_ADDRESS=$(lncli getinfo | grep onion)
  if [[ -n "$LND_TOR_ADDRESS" ]]
  then
    echo "--------$0 - Your LND Tor address is:

    $LND_TOR_ADDRESS
    "
  fi
  echo "LND is fully active and working with Tor.
  To create a wallet do (without the $) :
  $ lncli create
  "
  exit 0
else
  echo "
  -------$0 - LND not yet active. Check manually using (without the $) :

  $ sudo systemctl status lnd
  "
fi
# break
# done
