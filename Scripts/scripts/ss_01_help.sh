#!/bin/bash

# standup script help

# TODO: add bold to flags & vars (echo -e "\x1b[1m bold") or using vars bold=$(tput bold) normal=$(tput sgr0)

# help definition
function help () {

# echo -e ''

bold=$(tput bold)
normal=$(tput sgr0)
underline=$(tput smul)

cat <<-END


--------------------------------------
${bold}Install StandUp Script on this server.${normal}
--------------------------------------

${underline}standup.sh${normal}

Blockchain Commons Standup Script
Contributor: jodobear 20-07-03

DISCLAIMER: It is not a good idea to store large amounts of Bitcoin on a VPS,
ideally you should use this as a watch-only wallet. This script is expiramental
and has not been widely tested. The creators are not responsible for loss of
funds. If you are not familiar with running a node or how Bitcoin works then we
urge you to use this in testnet so that you can use it as a learning tool.

TL;DR:
------

Enter the 'scripts' directory and source 'ss.sh' to install the node.

1. Using cli arguments:
-----------------------
$ source ./ss.sh -y --userpassword <password> -n testnet -p 10000 --no-hwi -l lnd --btcpay --esplora --tor-pubkey <tor-pubkey> --ssh-key <ssh-key> --sys-ssh-ip <ip_1, ip_2, ..>

This will first create a new user "standup" and set the <password> for that user. Then install Bitcoin Testnet pruned to 10000 Mb with no HWI, LND, BTCPAY Server, Esplora Server on the machine pre-authenticated with Tor so all communications are by default routed through Tor (even bitcoin core). It will add the passed SSH Key to authorized keys and add the comma separated list of IPs to the whitelist. It will set bitcoin to restart after a crash or reboot.

2. Exporting environment variables:
-----------------------------------
$ export NOPROMPT=true
$ export USERPASSOWRD=password
$ export NETWORK=testnet
$ export LIGHTNING=lnd
$ source ./ss.sh

This will first create a new user "standup" and set the <password> for that user. Then install a full bitcoin node on testnet with lnd.



This script can be installed on any Debian based system. By default this script will:

* Update the OS
* Set Automatic Updates On
* Create User: standup
* Install UFW
* Install Tor
* Install Bitcoin Core
* Install HWI**
* Install c-lightning**
* Setup Bitcoin Core, Lightning settings
* Make sure they start at reboot via systemd
* Start Bitcoin Core, Lightning

Optionally you can install:
---------------------------
* Install LND instead of c-lightning
* Install Esplora**
* Install BTCPay**

** To be implemented

You can run this script again if you desire to change your configuration.

Upon completion of the script there will be a QR code saved to /qrcode.png which
you can open and scan. You can use "$ sudo apt-get install fim" then:
"$ fim -a qrcode.png" to display the QR in a terminal (as root).

It is highly recommended to add a Tor V3 pubkey for cookie authentication so that
even if your QR code is compromised an attacker would not be able to access your
node. It is also recommended to delete the /qrcode.png, /standup.log, and
/standup.err files.

 --------------------------------------
|                Usage                 |
 --------------------------------------

0. Prerequisites
----------------

In order to run this script you need to be logged in as root, and enter in the commands listed below:

- The $ or $ represents a terminal commmand prompt, do not actually type in a $ or #.
- Data fields enclosed in <> are to be filled by you with appropriate values.

1. Give the root user a password, enter the following command and set a password:
$ sudo passwd

2. Switch to the root user:
$ su - root

3. Source the script:
# source standup.sh

NOTE: Before sourcing the script you may want to set certain environment variables. Bleow you will find the list of environment variables. To set the variables do:
#export <ENV_VARIABLE>=<value>

You can use the following optional arguments:

    -h --help : Display this help.
    -y : Install without prompting for confirming the setup

    Setup:
    ------
    # --no-startup-register : Do not set Bitcoind & Lightning to start after reboot.
    # --no-systemd-reload : Do not set Bitcoind & Lightning to start after crash.
    -v --vps : Pass when installing on a VPS.
    --userpassword : Password for the standup non-privileged account.

    VPS:
    ----
    -F --fqdn : Fully Qualified Hostname
    -H --hostname : Hostname of your server
    -R --region : Server's timezone location

    Bitcoin:
    --------
    -f --fastsync : Enables fast synchronization of blockchain*.
    -n --network : Default bitcoin network; either "mainnet", "testnet" or "regtest".
    --no-hwi : Do NOT install HWI.
    -p --prune : Install a prune node; integer value > 550.

    Lightning:
    ----------
    --no-ln : Do NOT install lightning.
    -l --lightning : Choose lightning implementation, either "c-lightning" or "lnd".
    --ln-alias : Enter name for your lightning node.

    Services:
    ---------
    --btcpay : Installs BTCPay Server.
    --esplora : Installs Esplora.

    Tor:
    ----
    -t --tor-pubkey : Automatically add the pubkey to the Tor authorized_clients directory, which means the user is Tor authenticated before the node is even installed. e.g. ./standup.sh --tor-pubkey "descriptor:x25519:NWJNEFU487H2BI3JFNKJENFKJWI3"

    SSH:
    ----
    --ssh-key : key for automated SSH logins to standup non-privileged account.
    --sys-ssh-ip : Comma separated list of IPs that can use SSH.

*DISCLAIMER: It is always better to let your node validate blocks from the beginning. This script uses blockchain data signed by BTCPay Server. Trust at your own risk.

2. Environment Variables:
-------------------------

    # system
    --------
    NOPROMPT=true/false, set it to install the setup without prompting for confirmation.
    # START=true/false, start bitcoind & lightning after installation. Default: true.
    # STARTUP_REGISTER=true/false, Do not set Bitcoind & Lightning to start after reboot. Default: true.
    # SYSTEMD_RELOAD=true/false, Do not set Bitcoind & Lightning to start after crash. Default: true.
    VPS=true/false, set it to true if setting up on a VPS. Default: false.
    USERPASSWORD="", set password for user standup. Default: empty.

    #vps
    ----
    FQDN="", enter your fully qualified hostname. Example: my-awesome-node.my-awesome-domain.com
    HOSTNAME="", enter your hostname. Example: my-awesome-node.
    REGION="", enter your server's timezone location. Example Asia/Singapore.

    # bitcoind
    ----------
    NETFORK="mainnet", "testnet" or "regtest", Bitcoin network to use. Default: "mainnet".
    PRUNE="", Integer value to specify level of prune node.  Minimum value is 550. Default: empty(0).
    FASTSYNC=true/false, If you want to speed up the Initial Block Download then set it to true. Default: false.
    HWI=true/false, Choose to install HWI. Default: true.

    # lightning
    -----------
    LIGHTNING="c-lightning"/"lnd"/false, choose lightning network implementation or pass --no-ln to not install lightning. Default: "c-lightning".
    LN_ALIAS="", enter a name for your lightning node. Default: "Standup.

    # services
    ----------
    ESPLORA=true/false, Choose to install Esplora. Default: false.
    BTCPAYSERVER=true/false, Choose to install BTCPay Server. Default: false.
    # Tor
    TOR_PUBKEY="<string>" Tor Public Key. Default: empty.

    # ssh
    SSH_KEY="" key for automated SSH logins to standup non-privileged account. Default: empty.
    SYS_SSH_IP="" comma separated list of IPs that can use SSH. Default: empty.

----------------

END
}

help