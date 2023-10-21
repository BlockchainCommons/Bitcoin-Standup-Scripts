#!/bin/bash

# standup script - Tor installation

####
# 4. Install latest stable tor
####

# Download tor
echo "
----------------
  $MESSAGE_PREFIX Installing Tor
----------------
"
#  To use source lines with https:// in /etc/apt/sources.list the apt-transport-https package is required. Install it with:
if [ -z "$(which apt-transport-https)" ]; then
  apt-get install apt-transport-https -y
  echo "
$MESSAGE_PREFIX apt-transport-https installed
  "
fi

# To download bitcoin using onion site, we need torsocks
if [ -z "$(which torsocks)" ]; then
  apt-get install torsocks -y
  echo "
$MESSAGE_PREFIX torsocks installed
  "
fi

# We need to set up our package repository before you can fetch Tor. First, you need to figure out the name of your distribution:
DEBIAN_VERSION=$(lsb_release -c | awk '{ print $2 }')

# You need to add the following entries to /etc/apt/sources.list:
cat >> /etc/apt/sources.list << EOF
deb https://deb.torproject.org/torproject.org $DEBIAN_VERSION main
deb-src https://deb.torproject.org/torproject.org $DEBIAN_VERSION main
EOF

# Then add the gpg key used to sign the packages by running:
# apt-key adv --recv-keys --keyserver keys.gnupg.net  74A941BA219EC810
sudo wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import
sudo gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

# Update system, install and run tor as a service
sudo apt update
sudo apt install tor deb.torproject.org-keyring -y

# Setup hidden service
sed -i -e 's/#ControlPort 9051/ControlPort 9051/g' /etc/tor/torrc
sed -i -e 's/#CookieAuthentication 1/CookieAuthentication 1/g' /etc/tor/torrc
# for c-lightning
sed -i -e 's/#CookieAuthFileGroupReadable 1/CookieAuthFileGroupReadable 1/g' /etc/tor/torrc
sed -i -e 's/## address y:z./## address y:z.\
\
HiddenServiceDir \/var\/lib\/tor\/standup\/bitcoin\/\
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


if [[ -n "$(systemctl is-active tor) | grep active" ]]; then
echo "
$MESSAGE_PREFIX Tor installed and successfully started
"
fi

# add V3 authorized_clients public key if one exists
if [[ "$TOR_PUBKEY" != "" ]] && [[ "$TOR_PUBKEY" != "__UNDEFINED__" ]]; then
  # create the directory manually incase tor.service did not restart quickly enough
  mkdir /var/lib/tor/standup/authorized_clients

  # need to assign the owner
  chown -R debian-tor:debian-tor /var/lib/tor/standup/authorized_clients

  # Create the file for the pubkey
  touch /var/lib/tor/standup/authorized_clients/fullynoded.auth

  # Write the pubkey to the file
  echo "$TOR_PUBKEY" > /var/lib/tor/standup/authorized_clients/fullynoded.auth

  # Restart tor for authentication to take effect
  sudo systemctl restart tor.service

  echo "
  $MESSAGE_PREFIX Successfully added Tor V3 authentication
  "

else
  echo "
  $MESSAGE_PREFIX No Tor V3 authentication, anyone who gets access to your QR code can have full access to your node, ensure you do not store more then you are willing to lose and better yet use the node as a watch-only wallet
  "
fi
