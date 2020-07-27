#!/bin/bash

# NOT YET IMPLEMENTED

# standup - esplora

# install esplora
echo "
----------------
  $MESSAGE_PREFIX Installing Esplora
----------------
"

# get esplora repo & install
sudo -u standup git clone https://github.com/Blockstream/esplora ~standup/downloads/esplora
cd ~standup/downloads/esplora
$ npm install
$ export API_URL=http://localhost:3000/ # or https://blockstream.info/api/ if you don't have a local API server
# (see more config options below)
$ npm run dev-server

# edit config

# link: https://github.com/Blockstream/esplora