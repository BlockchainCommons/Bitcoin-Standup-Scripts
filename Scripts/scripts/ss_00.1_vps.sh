#!/bin/bash

# standup script - vps hostname settings

IPADDR=""

# Check for FQDN & HOSTNAME if --vps
if "$VPS" && [[ -z "$HOSTNAME" ]]
then
  echo "You provided the '--vps' flag but didn't provide --fqdn"
  while  [ -z "$HOSTNAME" ]
  do
    read -rp "You need to enter hostname of the server: " HOSTNAME
  done
fi

if "$VPS" && [[ -z "$FQDN" ]]
then
  echo "You provided the '--vps' flag but didn't provide --fqdn."
  while [ -z "$FQDN" ]
  do
    read -rp "You need to enter the fqdn of the server: " FQDN
  done
fi

if "$VPS" && [[ -z "$REGION" ]]
then
  echo "You provided the '--vps' flag but didn't provide --region."
  while [ -z "$REGION" ]
  do
    read -rp "You need to enter the region of the server to set the timezone: " REGION
  done
fi

echo "
----------------"
HOSTNAME: $HOSTNAME" > /etc/hostname
----------------
"
/bin/hostname "$HOSTNAME"

# Set the variable $IPADDR to the IP address the new Linode receives.
IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

echo "$0 - Set hostname as $FQDN ($IPADDR)"
echo "
  ***********************"
    $0 - TODO: Put $FQDN with IP $IPADDR in your main DNS file."
  ***********************
"
echo "$0 - Set Time Zone to $REGION"
echo $REGION > /etc/timezone
cp /usr/share/zoneinfo/${REGION} /etc/localtime

echo "
  -------$0 - Hostname, IP address and timezon are set. Put $FQDN with IP $IPADDR in your main DNS file.
  "
# Add localhost aliases

echo "127.0.0.1    localhost" > /etc/hosts
echo "127.0.1.1 $FQDN $HOSTNAME" >> /etc/hosts

echo "$0 - Set localhost"