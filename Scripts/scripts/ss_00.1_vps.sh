#!/bin/bash

# standup script - vps hostname settings

IPADDR=""

# Check for FQDN & HOSTNAME if --vps
if "$VPS" && [[ -z "$HOSTNAME" ]] || [[ "$HOSTNAME" == "__UNDEFINED__" ]]; then
  echo "
  $MESSAGE_PREFIX Hostname not provided.
  "
  while  [ -z "$HOSTNAME" ]; do
    read -rp "Enter hostname of the server: " HOSTNAME
  done
fi

if "$VPS" && [[ -z "$FQDN" ]] || [[ "$FQDN" == "__UNDEFINED__" ]]; then
  echo "
  $MESSAGE_PREFIX FQDN not provided. Please provide a domain name."
  while [ -z "$FQDN" ]; do
    read -rp "Enter the fqdn of the server: " FQDN
  done
fi

if "$VPS" && [[ -z "$REGION" ]] || [[ "$REGION" == "__UNDEFINED__" ]]; then
  echo "
  $MESSAGE_PREFIX Region of the server not provided. It is required to set the timezone.
  "
  while [ -z "$REGION" ]; do
    read -rp "Enter the region of the server: " REGION
  done
fi

echo $HOSTNAME > /etc/hostname

/bin/hostname "$HOSTNAME"

# Set the variable $IPADDR to the IP address the new Linode receives.
apt-get -qq -y install net-tools
IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

echo "$MESSAGE_PREFIX Set hostname as $FQDN ($IPADDR)"
echo "
  ***********************
    $MESSAGE_PREFIX TODO: Put $FQDN with IP $IPADDR in your main DNS file.
  ***********************
"
echo "$MESSAGE_PREFIX Set Time Zone to $REGION"
echo $REGION > /etc/timezone
cp /usr/share/zoneinfo/${REGION} /etc/localtime

echo "
  $MESSAGE_PREFIX Hostname, IP address and timezon are set. Put $FQDN with IP $IPADDR in your main DNS file.
  "
# Add localhost aliases

echo "127.0.0.1   localhost" > /etc/hosts
echo "127.0.1.1   $FQDN $HOSTNAME" >> /etc/hosts

echo "$MESSAGE_PREFIX - Set localhost"