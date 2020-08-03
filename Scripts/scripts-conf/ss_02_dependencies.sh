#!/bin/bash

# standup script - install dependencies

# Install haveged (a random number generator)
echo "
----------------
  $MESSAGE_PREFIX Installing haveged (a random number generator), gnupg2, git & make
----------------
"
apt-get install haveged gnupg2 git make -y
echo "
$MESSAGE_PREFIX haveged, gnupg2, git & make installed successfully
"

# Set system to automatically update
echo "
----------------
$MESSAGE_PREFIX setting system to automatically update
----------------
"
echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true" | debconf-set-selections
apt-get -y install unattended-upgrades
echo "
$MESSAGE_PREFIX Debian Packages updated
"
# Get uncomplicated firewall and deny all incoming connections except SSH
if [ -z "$(which ufw)" ]; then
  echo "
$MESSAGE_PREFIX Installing ufw
  "
  apt-get install ufw
fi

ufw allow ssh
ufw --force enable

echo "
$MESSAGE_PREFIX ufw is installed and enabled.
"