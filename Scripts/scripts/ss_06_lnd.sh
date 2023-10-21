#!/bin/bash

# standup script - install lnd

echo "
----------------
  $MESSAGE_PREFIX installing LND
----------------
"

# install Go
GO_VERSION="go1.14.4"
OS="linux"
ARCH="amd64"
GOSHA="aed845e4185a0b2a3c3d5e1d0a35491702c55889192bb9c30e67a3de6849c067"

## check & remove older go version
if [[ -n $(which go) ]]; then
  if [[ $(go version | awk '{print $3}') != "$GO_VERSION" ]]; then
    rm -rf /usr/local/go
  fi
fi

## get go
sudo -u standup wget --progress=bar:force https://dl.google.com/go/"$GO_VERSION"."$OS"-"$ARCH".tar.gz -O ~standup/"$GO_VERSION"."$OS"-"$ARCH".tar.gz
GOTARSHA=$(sudo -u standup /usr/bin/sha256sum ~standup/"$GO_VERSION"."$OS"-"$ARCH".tar.gz | awk -F " " '{ print $1 }')

if [[ "$GOTARSHA" != "$GOSHA" ]]; then
  echo "
  $MESSAGE_PREFIX Go checksum validation failed. Exiting.
  "
  return 201
else
  echo "
  $MESSAGE_PREFIX Go checksum validated. Continuing with installing LND.
  "
fi

# get go_sha from website to check
sudo -u standup /bin/tar xzf ~standup/"$GO_VERSION"."$OS"-"$ARCH".tar.gz -C ~standup
sudo mv ~standup/go /usr/local

export PATH="$PATH":/usr/local/go/bin:"$GOPATH"/bin
export GOPATH=~standup/gocode

# test go
if [[ $(go version | awk '{print $3}') = "$GO_VERSION" ]]; then
  echo "
$MESSAGE_PREFIX $GO_VERSION successfully installed
  "
else
  echo "
$MESSAGE_PREFIX Go not installed, cannot install lnd
  "
  return 202
fi

# build lnd
LND_VERSION="v0.11.0-beta.rc4"
echo "
$MESSAGE_PREFIX getting lnd... depending on your network it can take more than an hour. With good network it usually takes about 5-10 mins.
"
go get -d github.com/lightningnetwork/lnd
git checkout $LND_VERSION
cd "$GOPATH"/src/github.com/lightningnetwork/lnd
make
make install # installs to /home/standup/gocode/bin which is $GOPATH/bin

# go back to script directory
cd "$SCRIPTS_DIR"

sudo cp $GOPATH/bin/lnd $GOPATH/bin/lncli /usr/bin

# create necessary directories
mkdir -p /etc/lnd
mkdir -p /var/lib/lnd
chown standup:standup -R /var/lib/lnd

BTC_NETWORK=""
if [[ "$NETWORK" = "mainnet" ]]; then
  BTC_NETWORK="bitcoin.mainnet=1"
elif [[ "$NETWORK" = "testnet" ]]; then
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
listen=0.0.0.0:9735
debuglevel=debug

[Bitcoin]
bitcoin.active=1
bitcoin.node=bitcoind
bitcoin.dir=$BTC_DATA_DIR
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

# set appropriate permissions
chmod 644 /etc/lnd/lnd.conf

# create soft link to the lnd data dir
ln -s /var/lib/lnd ~standup/.lnd

# add tor configuration to torrc
sed -i -e 's/HiddenServicePort 1309 127.0.0.1:8332/HiddenServicePort 1309 127.0.0.1:8332\
HiddenServiceDir \/var\/lib\/tor\/standup\/lnd\/\
HiddenServiceVersion 3\
HiddenServicePort 1234 127.0.0.1:9735/g' /etc/tor/torrc

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


# enable lnd service
sudo systemctl restart tor
sleep 4
sudo systemctl enable lnd
sudo systemctl start lnd

# check if lnd running
echo "
$MESSAGE_PREFIX Checking if LND is running
"
LND_VERSION=$(lnd --version)

if [[ $(systemctl status lnd | grep active | awk '{print $2}') = "active" ]]; then
  echo "
  $MESSAGE_PREFIX installed $LND_VERSION
  $MESSAGE_PREFIX LND service now is active.
  "
  echo "LND is fully active and working with Tor.
To interact with LND first create a wallet (without the $):
  $ lncli create
  "
else
  echo "
  $MESSAGE_PREFIX LND not yet active. Check manually using (without the $) :
  $ sudo systemctl status lnd
  "
fi
