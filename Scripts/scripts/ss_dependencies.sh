#!/bin/bash

# standup script - install dependencies

# Install haveged (a random number generator)
echo "
----------------
"
echo "$0 - Installing haveged (a random number generator), gnupg2 & git"
echo "
----------------
"
apt-get install haveged gnupg2 git -y
echo "
----------------$0 - haveged, gnupg2 & git installed successfully
"

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
----------------$0 - Debian Packages updated
"
# Get uncomplicated firewall and deny all incoming connections except SSH
if [ -z "$(which ufw)" ]
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
ufw --force enable

echo "
----------------$0 - ufw is installed and enabled.
"