#!/bin/bash

# standup script - lightning installation

# install c-lightning
if [[ "$LIGHTNING" == "c-lightning" ]]
then
  export CLN_VERSION="v0.8.2.1"
  export CLN_DIR="~standup/clightning"

  echo "
-----------
  Downloading dependencies
-----------
  "
  apt-get install -y \
  autoconf automake build-essential git libtool libgmp-dev \
  libsqlite3-dev python3 python3-mako net-tools zlib1g-dev libsodium-dev \
  gettext valgrind python3-pip libpq-dev

  echo "
-----------
  Downloading & Installing c-lightning
-----------
  "
  # get clightning binary from github
  cd /tmp
  sudo -u standup git clone https://github.com/ElementsProject/lightning.git ~standup/lightning
  cd ~standup/lightning
  pip3 install -r requirements.txt
  ./configure
  make
  sudo make install
  cd /


  # start lightningd
  
#   cat >> ~standup/.lightning/config << EOF
# proxy=127.0.0.1:9050
# bind-addr=127.0.0.1:9735
# addr=statictor:127.0.0.1:9051
# always-use-proxy=true
# EOF

# /bin/chown standup ~standup/.lightning/config
# /bin/chmod 600 ~standup/.lightning/config

# echo "
# -------$0 - Setting up Bitcoin as a systemd service.
# "

# sudo cat > /etc/systemd/system/bitcoind.service << EOF
# # It is not recommended to modify this file in-place, because it will
# # be overwritten during package upgrades. If you want to add further
# # options or overwrite existing ones then use
# # $ systemctl edit bitcoind.service
# # See "man systemd.service" for details.
# # Note that almost all daemon options could be specified in
# # /etc/lightning/config, except for those explicitly specified as arguments
# # in ExecStart=
# [Unit]
# Description=c-lightning daemon
# After=tor.service
# Requires=tor.service
# [Service]
# ExecStart=/usr/local/bin/lightningd -conf=/home/standup/.lightning/config
# # Process management
# ####################
# Type=simple
# PIDFile=/run/lightning/lightningd.pid
# Restart=on-failure
# # Directory creation and permissions
# ####################################
# # Run as lightningd:lightningd
# User=standup
# Group=sudo
# # /run/lightningd
# RuntimeDirectory=lightningd
# RuntimeDirectoryMode=0710
# # Hardening measures
# ####################
# # Provide a private /tmp and /var/tmp.
# PrivateTmp=true
# # Mount /usr, /boot/ and /etc read-only for the process.
# ProtectSystem=full
# # Disallow the process and all of its children to gain
# # new privileges through execve().
# NoNewPrivileges=true
# # Use a new /dev namespace only populated with API pseudo devices
# # such as /dev/null, /dev/zero and /dev/random.
# PrivateDevices=true
# # Deny the creation of writable and executable memory mappings.
# MemoryDenyWriteExecute=true
# [Install]
# WantedBy=multi-user.target
# EOF

# echo "
# -------$0 - lightningd service active
# "
# sudo systemctl enable lightningd.service
# sudo systemctl start lightningd.service

#   if [ -n "$(systemctl is-active --quiet lightningd)" ]
#   then
#     echo "
#     -----------$0 - c-lightning Installed and started
#     "
#   fi
fi