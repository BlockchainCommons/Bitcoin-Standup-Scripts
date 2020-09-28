#!/bin/bash

# standup - esplora

echo "
----------------
  $MESSAGE_PREFIX Installing Esplora
----------------
"
ELECTRS_REPO="/home/standup/electrs"
ESPLORA_REPO="/home/standup/esplora"

# install rust
cd ~standup
sudo -u standup curl https://sh.rustup.rs -sSf | sudo -u standup sh -s -- -y

# install blockstream/electrs
apt install clang cmake -y # required for building rust-rocksdb
sudo -u standup git clone https://github.com/blockstream/electrs "$ELECTRS_REPO"
cd "$ELECTRS_REPO"
git checkout new-index

# create electrs config
cat >> electrs.toml << EOF
verbose=3
cors="$CORS":5000
electrum_rpc_addr=127.0.0.1:50001

db_dir="$ELECTRS_DB"

cookie="$RPCUSER:$RPCPASSWORD"
EOF

# set config options
if "$LIGHTMODE" && "$LIMIT_BATCH_SIZE"; then
  echo "
  lightmode=true
  index_batch_size=10" >> ~standup/electrs/electrs.toml
  ELECTRS_SETUP="lightmode and limiting index batch size to 10."
elif "$LIGHTMODE" && ! "$LIMIT_BATCH_SIZE"; then
  echo "
  lightmode=true" >> ~standup/electrs/electrs.toml
  ELECTRS_SETUP="lightmode."
elif ! "$LIGHTMODE" && "$LIMIT_BATCH_SIZE"; then
  echo "
  index_batch_size=10" >> ~standup/electrs/electrs.toml
  ELECTRS_SETUP="fullmode and limiting batch size index to 10."
else
  ELECTRS_SETUP="full mode."
fi

ELECTRS_CMD="/home/standup/.cargo/bin/cargo run --release --bin electrs --"

# set systemd service
sudo cat > /etc/systemd/system/electrs.service << EOF
# It is not recommended to modify this file in-place, because it will
# be overwritten during package upgrades. If you want to add further
# options or overwrite existing ones then use
# $ systemctl edit electrs.service
# See "man systemd.service" for details.

[Unit]
Description=Electrs
Requires=bitcoind.service
After=bitcoind.service

[Service]
WorkingDirectory=/home/standup/electrs
ExecStart=$ELECTRS_CMD

# Process management
####################
Type=simple
PIDFile=/run/electrs/electrs.pid
TimeoutSec=60
Restart=on-failure
RestartSec=60
KillMode=process

# Directory creation and permissions
####################################
# Run as standup:standup
User=standup
Group=standup
# /run/electrs
RuntimeDirectory=electrs
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


# enable electrs service
systemctl restart tor
sleep 4
systemctl enable electrs.service
systemctl start electrs.service

# install node
echo "
$MESSAGE_PREFIX installing nodejs
"
apt-get install curl software-properties-common -y
curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
apt-get install nodejs -y

#  get esplora & set electrs api url
sudo -u standup git clone https://github.com/Blockstream/esplora "$ESPLORA_REPO"
cd "$ESPLORA_REPO"
echo "
$MESSAGE_PREFIX running npm install
"
sudo -u standup npm install
# echo "
# $MESSAGE_PREFIX running install npx
# "
# sudo -u standup npm install npx
echo "
$MESSAGE_PREFIX running npm audit fix
"
sudo -u standup npm audit fix
# echo "
# $MESSAGE_PREFIX running npx browserslist --update-db
# "
# sudo -u standup npx browserslist --update-db
export API_URL=http://localhost:3000/
export SITE_TITLE="Standup Block Explorer"
export SITE_DESC="Standup Block Explorer"

# setup HiddenService
sed -i -e 's/HiddenServicePort 1309 127.0.0.1:8332/HiddenServicePort 1309 127.0.0.1:8332\
\
HiddenServiceDir \/var\/lib\/tor\/standup\/esplora\/\
HiddenServiceVersion 3\
HiddenServicePort 80 127.0.0.1:5000/g' /etc/tor/torrc

sed -i -e 's/HiddenServicePort 80 127.0.0.1:5000/HiddenServicePort 80 127.0.0.1:5000\
\
HiddenServiceDir \/var\/lib\/tor\/standup\/esplora_noscript\/\
HiddenServiceVersion 3\
HiddenServicePort 80 127.0.0.1:5001/g' /etc/tor/torrc


# restart tor
systemctl restart tor
sleep 4

ESPLORA_HS="$(cat /var/lib/tor/standup/esplora/hostname)"
ESPLORA_NS_HS="$(cat /var/lib/tor/standup/esplora_noscript/hostname)"

cat >> ~standup/scripts/ss_start-esplora.sh << EOF
#!/bin/bash

cd $ESPLORA_REPO
echo "
Esplora server is starting and will be available at: http://$CORS:5000
Esplora onion address is:
******************************************************************
$ESPLORA_HS
******************************************************************
"
npm run dist
EOF

chmod +x ~standup/scripts/ss_start-esplora.sh

cat >> ~standup/scripts/ss_start-esplora_noscript.sh << EOF
#!/bin/bash


cd $ESPLORA_REPO
export STATIC_ROOT="http://localhost:5000/" # for loading CSS, images and fonts
export NOSCRIPT_REDIR="http://localhost:5001/"
export NOSCRIPT_REDIR_BASE="http://localhost:5001/"

echo "
Prerendered server is starting & will be available at: http://localhost:5001/
Onion address for prerendered server is:
******************************************************************
$ESPLORA_NS_HS
******************************************************************
"
npm run prerender-server
EOF

chmod +x ~standup/scripts/ss_start-esplora_noscript.sh

echo "
----------------------------------------------------------------
$MESSAGE_PREFIX Esplora has been setup with Electrs in $ELECTRS_SETUP
----------------------------------------------------------------

* Electrs is: $(systemctl status electrs | grep active | awk '{print $2}')

* To start Esplora, run 'ss_start-esplora.sh' located at '/home/standup/scripts' directory.

* If you want to run server with pre-rendered assets for NoScript compatibility then run 'ss_start-esplora_noscript.sh'.

For further information checkout documentation:

Electrs: https://github.com/Blockstream/electrs
Esplora: https://github.com/Blockstream/esplora
"
