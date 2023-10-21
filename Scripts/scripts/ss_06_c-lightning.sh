#!/bin/bash

# standup script - install c-lightning

echo "
----------------
  $MESSAGE_PREFIX installing c-lightning
----------------
"

export CLN_VERSION="v0.9.1"
export LIGHTNING_DIR="/home/standup/.lightning"

echo "

$MESSAGE_PREFIX installing c-lightning dependencies

"

apt-get install -y \
autoconf automake build-essential git libtool libgmp-dev \
libsqlite3-dev python3 python3-mako net-tools zlib1g-dev \
libsodium-dev gettext valgrind python3-pip libpq-dev

echo "
$MESSAGE_PREFIX downloading & Installing c-lightning
"
# get & compile clightning from github
sudo -u standup git clone https://github.com/ElementsProject/lightning.git ~standup/lightning
cd ~standup/lightning
git checkout $CLN_VERSION
python3 -m pip install -r requirements.txt
./configure
make -j$(nproc --ignore=1) --quiet
sudo make install

# get back to script directory
cd "$SCRIPTS_DIR"

# lightningd config
mkdir -m 760 "$LIGHTNING_DIR"
chown standup -R "$LIGHTNING_DIR"
cat >> "$LIGHTNING_DIR"/config << EOF
alias=StandUp

log-level=debug:plugin
log-prefix=standup

bitcoin-datadir=$FULL_BTC_DATA_DIR
# bitcoin-rpcuser=****
# bitcoin-rpcpassword=****
# bitcoin-rpcconnect=127.0.0.1
# bitcoin-rpcport=8332

# outgoing Tor connection
proxy=127.0.0.1:9050
# listen on all interfaces
bind-addr=
# listen only clearnet
bind-addr=127.0.0.1:9735
addr=statictor:127.0.0.1:9051
# only use Tor for outgoing communication
always-use-proxy=true
EOF

/bin/chmod 640 "$LIGHTNING_DIR"/config

# create log file
touch "$LIGHTNING_DIR"/lightning.log

# add tor configuration to torrc
sed -i -e 's/HiddenServicePort 1309 127.0.0.1:8332/HiddenServicePort 1309 127.0.0.1:8332\
\
HiddenServiceDir \/var\/lib\/tor\/standup\/lightningd-service_v3\/\
HiddenServiceVersion 3\
HiddenServicePort 1234 127.0.0.1:9735/g' /etc/tor/torrc

#################
# add http-plugin
#################
if "$CLN_HTTP_PLUGIN"; then
  echo "
  $MESSAGE_PREFIX installing Rust lang.
  "
  cd ~standup
  /usr/sbin/runuser -l standup -c 'curl https://sh.rustup.rs -sSf | sh -s -- -y'
  source ~standup/.cargo/env
  echo "
  $MESSAGE_PREFIX $(runsuer -l standup rustc - version) installed.
  "
  # get back to script directory & create plugins direcotry
  cd "$SCRIPTS_DIR"
  mkdir "$LIGHTNING_DIR"/plugins/

  # get http-plugin & build
  echo "
  $MESSAGE_PREFIX getting c-lightning http-plugin.
  "
  sudo -u standup git clone https://github.com/Start9Labs/c-lightning-http-plugin.git "$LIGHTNING_DIR"/plugings/
  cd "$LIGHTNING_DIR"/plugings/c-lightning-http-plugin/
  cargo build --release
  chmod a+x /home/you/.lightning/plugins/c-lightning-http-plugin/target/release/c-lightning-http-plugin
  if [[ -z "$HTTP_PASS" ]]; then
    while [[ -z "$HTTP_PASS" ]]; do
      read -rp "Provide a strong password for https-plugin" HTTP_PASS
    done
  fi

  # add config options
  echo "
plugin=/home/standup/.lightning/plugins/c-lightning-http-plugin/target/release/c-lightning-http-plugin
http-pass=$HTTP_PASS
https-port=1312
" >> "$LIGHTNING_DIR"/config

  # create HS for plugin
  sed -i -e 's/HiddenServicePort 1234 127.0.0.1:9735/HiddenServicePort 1234 127.0.0.1:9735\
HiddenServiceDir \/var\/lib\/tor\/standup\/lightningd-http-plugin_v3\/\
HiddenServiceVersion 3\
HiddenServicePort 1312 127.0.0.1:1312/g' /etc/tor/torrc
fi

echo "
$MESSAGE_PREFIX Setting up c-lightning as a systemd service.
"

cat > /etc/systemd/system/lightningd.service << EOF
# It is not recommended to modify this file in-place, because it will
# be overwritten during package upgrades. If you want to add further
# options or overwrite existing ones then use
# $ systemctl edit bitcoind.service
# See "man systemd.service" for details.
# Note that almost all daemon options could be specified in
# /etc/lightning/config, except for those explicitly specified as arguments
# in ExecStart=
[Unit]
Description=c-lightning daemon
After=tor.service
Requires=tor.service
[Service]
ExecStart=/usr/local/bin/lightningd -conf=/home/standup/.lightning/config
# Process management
####################
Type=simple
PIDFile=/run/lightning/lightningd.pid
Restart=on-failure
# Directory creation and permissions
####################################
# Run as lightningd:lightningd
User=standup
Group=standup
# /run/lightningd
RuntimeDirectory=lightningd
RuntimeDirectoryMode=0710
# Hardening measures
####################
# Provide a private /tmp and /var/tmp.
PrivateTmp=true
# Mount /usr, /boot/ and /etc read-only for the process.
ProtectSystem=full
# Disallow the process and all of its children to gain
# new privileges through execve().
NoNewPrivileges=true
# Use a new /dev namespace only populated with API pseudo devices
# such as /dev/null, /dev/zero and /dev/random.
PrivateDevices=true
# Deny the creation of writable and executable memory mappings.
MemoryDenyWriteExecute=true
[Install]
WantedBy=multi-user.target
EOF

# enable lightnind service
sudo systemctl restart tor
sleep 4
sudo systemctl enable lightningd.service
sudo systemctl start lightningd.service

if [ $(systemctl status lightningd | grep active | awk '{print $2}') = "active" ]; then
  echo "
$MESSAGE_PREFIX c-lightning Installed and started
  Wait for the bitcoind to fully sync with the blockchain and then interact with lightningd.
  "
else
  echo "
$MESSAGE_PREFIX c-lightning not yet active.
  "
fi