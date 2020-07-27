#!/bin/bash

# NOT YET IMPLEMENTED

# standup - Ride The Lightning

echo "
----------------
  $MESSAGE_PREFIX Installing Esplora
----------------
"

# dependencies
apt install nodejs npm
echo "
-----------
$MESSAGE_PREFIX Node.js version $(node -v) installed.
-----------
"

# get repo and install
sudo -u standup git clone https://github.com/Ride-The-Lightning/RTL.git ~standup/RTL
cd ~standup/RTL
npm install --only=prod
mv ./sample-RTL-Config.json RTL-config.json

if [[ "$LIGHTNING" = "lnd" ]]
then
  # find admin.macroon & lnd.conf
  # update rtl-config
elif [[ "$LIGHTNING" = "c-lightning" ]]
then
  # install cl-rest
  # rename sample-cl-rest-config.json to cl-rest-config.json
  # update cl-rest-config
  # locate acess.macroon from cl-rest
  # update rtl-config
fi

# create executable script to start rtl

# links:
# lnd: https://github.com/Ride-The-Lightning/RTL
# cln: https://github.com/Ride-The-Lightning/c-lightning-REST
# cl-rest: https://github.com/Ride-The-Lightning/c-lightning-REST