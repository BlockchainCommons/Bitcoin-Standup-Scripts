#!/bin/bash

# standup script help

# help definition
function help () {

bold=$(tput bold)
normal=$(tput sgr0)
underline=$(tput smul)

cat <<-END


---------------------------------
${bold}Blockchain Commons Standup Script${normal}
---------------------------------

Contributor: jodobear 20-07-03

${bold}DISCLAIMER:${normal} It is not a good idea to store large amounts of Bitcoin on a VPS, ideally you should use this as a watch-only wallet. This script is a work-in-progress and has not been widely tested. The creators are not responsible for loss of funds. If you are not familiar with running a node or how Bitcoin works then we urge you to use this in testnet so that you can use it as a learning tool.


--------------------------------------
${bold}                Usage                 ${normal}
--------------------------------------

The script is inteded for a fresh bitcoin setup. Re-running the script on an already setup server is intended only for advanced users. In order to run this script ${bold}you need to be logged in as root${normal}, and enter in the commands listed below:

(The $ or # represents a terminal commmand prompt, do not actually type in a $ or #.)

1. Give the root user a password, enter the following command and set a password:
$ ${bold}sudo passwd${normal}

2. Switch to the root user:
$ ${bold}sudo su${normal}

3. Edit config for your node setup using your favourite text editor:
# ${bold}nano ss.conf${normal}

4. Source the script:
# ${bold}source ss_00_main.sh${normal}

5. Display this help:
# ${bold}source ss_00_main.sh -h${normal}

This script can be installed on any Debian based system. By default this script will:

- Update the OS
- Set Automatic Updates On
- Create User: standup
- Install UFW, haveguard, gnupg2, git & make
- Install Tor
- Install Bitcoin Core on mainnet with txindex=1 if setting up unpruned node.
- Setup Bitcoin Core as systemd service and to start at reboot or after a crash.
- Start Bitcoin Core

Optionally you can install:
---------------------------
- Install c-lightning or LND
- Install Esplora
- Install BTCPay**


** Work-in-progress

QR Code:
--------
Upon completion of the script there will be a QR code saved to /qrcode.png which you can open and scan:

1. Install fim:
$ ${bold}sudo apt-get install fim${normal}
2. Then, display the QR code in terminal (as root):
# ${bold}fim -a qrcode.png${normal}

It is highly recommended to add a Tor V3 pubkey for cookie authentication so that even if your QR code is compromised an attacker would not be able to access your node.

${bold}It is recommended to delete the /qrcode.png.
Additionally, unless you face installation issues and need to assisstance delete /standup.log, and /standup.err${normal}

----------------------------------------------------------------------------------------------------------------

END
}

help