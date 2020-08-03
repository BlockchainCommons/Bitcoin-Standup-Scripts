#!/bin/bash

# NOT YET IMPLEMENTED

# standup - bitcoin-core hwi (Hardware Wallet Interface)
echo "
----------------
  $MESSAGE_PREFIX Installing Esplora
----------------
"
# check dependencies

apt install libusb-1.0-0-dev libudev-dev python3-dev

# install hwi

sudo -u standup git clone https://github.com/bitcoin-core/HWI.git -O ~standup/downloads/HWI
cd ~standup/downloads/HWI
poetry install # or 'pip3 install .' or 'python3 setup.py install'

# create script to setup device

# hwi: https://github.com/bitcoin-core/HWI
# specter: https://github.com/cryptoadvance/specter-desktop
# lily: https://github.com/KayBeSee/lily-wallet