#!/bin/bash

# standup script - setup user and ssh access

if [ -z "$(cat /etc/shadow | grep standup)" ] && [ -z "$(groups standup)" ]; then
  echo "
----------------
  $MESSAGE_PREFIX Creating user standup
----------------
  "
  # Create "standup" group & user with optional password and give them sudo capability
  /usr/sbin/groupadd standup
  /usr/sbin/useradd -m -p `perl -e 'printf("%s\n",crypt($ARGV[0],"password"))' "$USERPASSWORD"` -g sudo -s /bin/bash standup
  /usr/sbin/adduser standup sudo
  /usr/sbin/adduser standup standup

  # make scripts directory for useful scripts
  mkdir /home/standup/scripts
  chown standup /home/standup/scripts
  echo "
$MESSAGE_PREFIX User standup created with sudo access.
  "
else
  echo "
  ----------------
  $MESSAGE_PREFIX User standup already exists.
  ----------------"
fi

# Setup SSH Key if the user added one as an argument
if [ -n "$SSH_KEY" ] && [[ "$SSH_KEY" != "__UNDEFINED__" ]]; then
  mkdir ~standup/.ssh
  echo "$SSH_KEY" >> ~standup/.ssh/authorized_keys
  chown -R standup ~standup/.ssh
  echo "
----------------
$MESSAGE_PREFIX Added .ssh key to standup.
----------------
  "
fi

# Setup SSH allowed IP's if the user added any as an argument
if [ -n "$SYS_SSH_IP" ] && [[ "$SYS_SSH_IP" != "__UNDEFINED__" ]]; then
  echo "sshd: $SYS_SSH_IP" >> /etc/hosts.allow
  echo "sshd: ALL" >> /etc/hosts.deny
  echo "
----------------
$MESSAGE_PREFIX Limited SSH access.
----------------
  "
else
  echo "
  ****************
  $MESSAGE_PREFIX WARNING: Your SSH access is not limited; this is a major security hole!
  ****************
  "
fi