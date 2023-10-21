#!/bin/bash

# standup - install btcpayserver

echo "
----------------
  $MESSAGE_PREFIX Installing BTCPay Server
----------------
"

if "$BTCPAYSERVER" && [[ -z "$BTCPAY_HOST" ]] || [[ "$BTCPAY_HOST" == "__UNDEFINED__" ]]; then
  echo "You provided the '--btcpay' flag but didn't provide --btcpay-host"
  while  [ -z "$BTCPAY_HOST" ]; do
    read -rp "Enter domain name where you will host BTCPay Server: " BTCPAY_HOST
  done
fi

if "$BTCPAYSERVER" && [[ -z "$BTCPAY_LN" ]] || [[ "$BTCPAY_LN" == "__UNDEFINED__" ]]; then
  echo "You provided the '--btcpay' flag but didn't provide --btcpay-ln"
  while  [ -z "$BTCPAY_HOST" ]; do
    read -rp "Enter lightning network implementation for BTCPay Server: " BTCPAY_LN
  done
fi

# install dependencies
# .NET Core SDK 3.1
# echo "
# $MESSAGE_PREFIX installing .NET Core SDK 3.1 .. this will take a while!
# "
sudo -u standup wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O ~standup/packages-microsoft-prod.deb
dpkg -i ~standup/packages-microsoft-prod.deb
apt-get update
apt-get install -y dotnet-sdk-3.1

# opt out of .NET telemetry
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# get btcpay server
echo "
$MESSAGE_PREFIX getting btcpayserver-docker
"
sudo -u standup mkdir btcpayserver
sudo -u standup git clone https://github.com/btcpayserver/btcpayserver-docker ~standup/btcpayserver/btcpayserver-docker
cd ~standup/btcpayserver/btcpayserver-docker

# set env variables
export BTCPAY_HOST="$BTCPAY_HOST"
export NBITCOIN_NETWORK="$NETWORK"
export BTCPAYGEN_CRYPTO1="btc"
export BTCPAYGEN_REVERSEPROXY="nginx"
export BTCPAYGEN_LIGHTNING="$BTCPAY_LN"
export BTCPAY_ENABLE_SSH=true

# install
echo "
$MESSAGE_PREFIX installing btcpayserver
"
. ./btcpay-setup.sh -i

# shut the container
echo "
$MESSAGE_PREFIX shutting down btcpayserver to link existing bitcoin data dir
"
. ./btcpay-down.sh
# # stop bitcoind
# systemctl stop bitcoind
# sleep 10

# delete _data & create symbolic link to host's bitcoin data
echo "
$MESSAGE_PREFIX removing btcpayserver bitcoin data dir
"
rm -r /var/lib/docker/volumes/generated_bitcoin_datadir/_data
echo "
$MESSAGE_PREFIX creating symlink between host bitcoind data dir and btcpayserver bitcoin data dir
"
ln -s $FULL_BTC_DATA_DIR /var/lib/docker/volumes/generated_bitcoin_datadir/_data

# start btcpay server
echo "
$MESSAGE_PREFIX starting bitcoind & BTCPayserver
"
# systemctl start bitcoind
# sleep 30
. ./btcpay-up.sh

BTCPAY_ONION_ADD=$(sudo cat /var/lib/docker/volumes/generated_tor_servicesdir/_data/BTCPayServer/hostname)
echo "
Your BTCPay Server Tor address is:
******************************************************************
$BTCPAY_ONION_ADD
******************************************************************
"
echo "
For further information on btcpay server, go to:
Docs: https://docs.btcpayserver.org
Chat: https://chat.btcpayserver.org
"
# back to scripts dir
cd "$SCRIPTS_DIR"
