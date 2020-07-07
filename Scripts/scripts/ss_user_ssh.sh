#!/bin/bash

# standup script - setup user and ssh access

if [ -z "$(cat /etc/shadow | grep standup)" ] && [ -z "$(groups standup)" ]
then
  echo "
----------------
  "
  echo "Creating user standup"
  echo "
----------------
  "
  # Create "standup" user with optional password and give them sudo capability
  /usr/sbin/useradd -m -p `perl -e 'printf("%s\n",crypt($ARGV[0],"password"))' "$USERPASSWORD"` -g sudo -s /bin/bash standup
  /usr/sbin/adduser standup sudo

  echo "
----------------
  "
  echo "$0 - User standup created with sudo access."
  echo "
----------------
  "
else
  echo "----------------"
  echo "User standup already exists."
  echo "----------------"
fi

# Setup SSH Key if the user added one as an argument
if [ -n "$SSH_KEY" ]
then
  mkdir ~standup/.ssh
  echo "$SSH_KEY" >> ~standup/.ssh/authorized_keys
  chown -R standup ~standup/.ssh
  echo "
----------------
  "
  echo "$0 - Added .ssh key to standup."
  echo "
----------------
  "
fi

# Setup SSH allowed IP's if the user added any as an argument
if [ -n "$SYS_SSH_IP" ]
then
  echo "sshd: $SYS_SSH_IP" >> /etc/hosts.allow
  echo "sshd: ALL" >> /etc/hosts.deny
  echo "
----------------
  "
  echo "$0 - Limited SSH access."
  echo "
----------------
  "
else
  echo "
  ****************
  "
  echo "$0 - WARNING: Your SSH access is not limited; this is a major security hole!"
  echo "
  ****************
  "
fi