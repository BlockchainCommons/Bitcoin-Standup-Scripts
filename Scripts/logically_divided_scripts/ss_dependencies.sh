#!/bin/bash

# standup script - install dependencies

# Install haveged (a random number generator)
if [ -z "$(which haveged)" ]
then
  echo "
----------------
  "
  echo "$0 - Installing haveged (a random number generator)"
  echo "
----------------
  "
  apt-get install haveged -y
echo "
----------------$0 - haveged installed successfully
"
else
  echo "
  ----------------$0 - haveged already installed"
fi

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

# Get GPG if not installed to verify signatures

if [ -z "$(which gpg)" ]
then
  echo "
----------------
  "
  echo "$0 - Installing gnupg2"
  echo "
----------------
  "
  apt-get install gnupg2 -y
  echo "
----------------$0 - Gnupg2 not found and installed
  "
fi
