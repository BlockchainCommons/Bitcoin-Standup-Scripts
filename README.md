# 🛠 Bitcoin-Standup Linux Scripts
### _by Peter Denton, Shannon Appelcline, and Christopher Allen_

This script installs the latest stable version of Tor, Bitcoin Core, Uncomplicated Firewall (UFW), Debian updates, enables automatic updates for Debian for good security practices, installs a random number generator, and optionally a QR encoder and an image displayer.

## Additional Information

For more information on *Bitcoin-Standup*:

1. The [Main *Bitcoin-Standup* Repo](https://github.com/BlockchainCommons/Bitcoin-Standup) contains general information on the project.
2. [Why Run a Full Node?](https://github.com/BlockchainCommons/Gordian/blob/master/Docs/Why-Full.md) details why you would want to run a full node in the first place.
3. [Security for Bitcoin-Standup](https://github.com/BlockchainCommons/Gordian/blob/master/Docs/Security.md) offers notes on ensuring the security of your *Bitcoin-Standup* node.

## Status — Work-in-Progress (0.8)

The *Bitcoin-Standup-Scripts* are updated every year or two for the newest versions of Bitcoin and Debian, and so remain a work-in-progress. We're also working toward improving the modularity of various plug-ins that could be installed.

## Version History

### 0.8.0, October 6, 2021

* Added Cypherpunkpay Installation, courtesy of [@nochiel](https://github.com/nochiel) and sponsorship from [HRF](https://hrf.org/).
* Updated scripts to Bitcoin Core 22.0

## Installation Instructions

There are two linux based StandUp scripts; `StandUp.sh` and `LinodeStandUp.sh`.

* `LinodeStandUp.sh` is built as a StackScript for the Linode platform and can be used as is. It's been tested on Debian 11 (Bullseye), with previous versions tested on Debian 9 (Stretch) and Debian 10 (Buster).
* `StandUp.sh` can be used on a Debian VPS and has been tested on Debian 11 (Bullseye), with previous versions tested on Debian 9 (Stretch) and Ubuntu 18.04.

You will use different installation methods depending on which script you use (or if you want to run the installation entirely by hand)

### Method One: Install Using `Standup.sh`

In order to run this script you need to be logged in as root, and enter in the commands listed below.
The `$` represents a terminal command prompt; do not actually type in a `$`.

1. Give the root user a password:
   `$ sudo passwd`

2. Switch to the root user:
   `$ su - root`

3. Create the file for the script:
   `$ nano standup.sh`

   - Nano is a text editor that works in a terminal, you need to paste the entire contents of the [Standup script](Scripts/StandUp.sh) into your terminal after running the above command. Then you can type:
      - `control x` (this starts to exit nano)
    - `y`         (this confirms you want to save the file)
    - `return`    (just press enter to confirm you want to save and exit)

4. Make sure the script is executable:
   `$ chmod +x standup.sh`

5. Run the script with the optional arguments like :
   `$ ./standup.sh "<insert Tor V3 pubkey>" "<insert node type>" "<insert ssh key>" "<insert ssh allowed IP's>" "<insert password for standup user>"`
   -  It is highly recommended to add a `Tor V3 pubkey` for cookie authentication, so that even if your QR code is compromised an attacker would not be able to access your node.
   -  The `node type` is  "Mainnet", "Pruned Mainnet", "Testnet", "Pruned Testnet", or "Private Regtest", default is "Pruned Testnet".
   -  If you supply a `SSH_KEY` in the arguments, you will be able to easily access your node via SSH using your rsa pubkey.
   -  If you add `SYS_SSH_IP`, you host willl only accept SSH connections from those IPs.
   -  The `password` is used for a user called `standup`.

### Method Two: Install Using `LinodeStandup.sh`

The `LinodeStandup.sh` script is intended for use at [Linode.com](https://linode.com). You can find more precise information on using it from our [Learning Bitcoin from the Command Line course](https://github.com/BlockchainCommons/Learning-Bitcoin-from-the-Command-Line/blob/master/02_1_Setting_Up_a_Bitcoin-Core_VPS_with_StackScript.md). The following is a summary.

First, copy the `LinodeStandup.sh` script to your Linode:

1. Copy the complete [LinodeStandup.sh script](https://github.com/BlockchainCommons/Bitcoin-Standup-Scripts/blob/master/Scripts/LinodeStandUp.sh).
2. Go to the [Stackscripts page](https://cloud.linode.com/stackscripts?type=account) on your Linode account; choose [Create New Stackscript](https://cloud.linode.com/stackscripts/create)
3. Paste `LinodeStandup.sh` into the "Script" area. Make sure you got it all, from the "#!/bin/bash" to the "exit 1"!
4. Choose "Debian 11" (Bullseye) for the "Target Images".
5. Click "Save".

Second, create a node based on the script:

6. On the [Stackscripts page](https://cloud.linode.com/stackscripts?type=account), click on the "..." to the right of your new script and choose "Deploy New Linode".
7. Fill in a hostname and the password for the "standup" user.
8. Choose an Installation Type in your options. This is likely "Mainnet" or "Pruned Mainnet" if you are setting up a node for usage and "Pruned Testnet" if you're just playing around.
9. Fill in any other advanced options.
10. Choose a region for where the Linode will be located.
11. Choose a Linnode plan. Our general experience is that a Linode 8GB is needed to store the whole blockchain if you choose unpruned "Mainnet", while for testnet and the pruned options (and regtest) you'll instead be dependent on memory, where a Linode 4GB will definitely be sufficient, and a Linode 2GB has worked or not on various versions of Bitcoin Core. (If it fails, you'll get out-of-memory errors.) For deployment you may wish to use "Dedicated CPU", but for everything else a "Shared CPU" should be sufficient.
12. Enter a root password.
13. Click "Create".

### Method Three: Install by Hand (Not Recommended)

Finally, if you prefer, you can install all of the packages for *Bitcoin-Standup* by hand. The  [Learning Bitcoin from the Command Line](https://github.com/ChristopherA/Learning-Bitcoin-from-the-Command-Line) course has [instructions on how to do so](https://github.com/BlockchainCommons/Learning-Bitcoin-from-the-Command-Line/blob/master/02_2_Setting_Up_Bitcoin_Core_Other.md), but those methodologies will only install a full node, not include `tor` and not linking with the Quick Connect API. As such, this methodology is not recommended, but is simply included to provide you with the widest breadth of options.

Because this by-hand methodology does not embody the full *Bitcoin-Standup* protocol, the following notes on what to do next do not apply.

### After Installation

By default the scripts set up a pruned testnet node and a Tor V3 hidden service controlling your `rpcport` and enable the firewall to only allow incoming connections for SSH. Tor and Bitcoin Core are set up as `systemd` services so that they start automatically after crashes or reboots. 

1. You should check the *Bitcoin-Standup* logs to ensure that the installation went correctly:
   `$ cat /standup.err`
   `$ cat /standup.log`

2. You can now scan a QR code from *Bitcoin-Standup* to link to a remote app such as [FullyNoded 2](https://github.com/BlockchainCommons/FullyNoded-2). There are two ways to do so.
   * A `btcstandup://` uri appears in plain text in the `/standup.log`. You can convert that to a QR Code.
   * Alternatively, you can directly access `/qrcode.png`, which you can open and scan. One way to do so is to `sudo apt-get install fim` then `fim -a qrcode.png` to display the QR in a terminal (as root).

3.  After reviewing your logs and accessing your QR code, you should remove the `/btcstandup.uri`, `/qrcode.png`, `/standup.log`, and `/standup.err` files.

   ```
   rm -R -f standup.log
   rm -R -f standup.err
   rm -R -f btcstandup.uri
   rm -R -f qrcode.png
   ```

## Installation Instructions Cypherpunkpay

Version 0.8.0 of the Bitcoin Standup Scripts added support for [Cypherpunkpay installation](https://cypherpunkpay.org/). Cypherpunkpay may be installed by inputting four variables:

* USECYPHERPUNKPAY ; set to YES
* CPPLITE ; for a lighter installation, usually set to YES
* XPUB ; the xpub for the wallet where you will receive your funds
* CPPCAUSE ; the title for your Cyperpunkpay donations

If you use the Linode Stackscript, you will be able to set these variables on the Stackscript deployment page; if you use the `.sh` scripts, you must find these lines in the script, uncomment them, and edit them as appropriate (particularly the `XPUB` and `CPPCAUSE` variables).

After running the script, you can verify that Cypherpunkpay is running with `systemctl status cypherpunkpay`:
```
# systemctl status cypherpunkpay
● cypherpunkpay.service - CypherpunkPay
     Loaded: loaded (/lib/systemd/system/cypherpunkpay.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2021-10-07 00:49:18 UTC; 1min 28s ago
   Main PID: 9136 (cypherpunkpay)
      Tasks: 37 (limit: 4680)
     Memory: 63.6M
        CPU: 1.404s
     CGroup: /system.slice/cypherpunkpay.service
             └─9136 /opt/venvs/cypherpunkpay/bin/python /usr/bin/cypherpunkpay
```
Once Cypherpunkpay is running, you will need to [integrate it into your website](https://cypherpunkpay.org/merchant/quick-start/).

## Financial Support

*Bitcoin-Standup* is a project of [Blockchain Commons](https://www.blockchaincommons.com/). We are proudly a "not-for-profit" social benefit corporation committed to open source & open development. Our work is funded entirely by donations and collaborative partnerships with people like you. Every contribution will be spent on building open tools, technologies, and techniques that sustain and advance blockchain and internet security infrastructure and promote an open web.

To financially support further development of *Bitcoin-Standup* and other projects, please consider becoming a Patron of Blockchain Commons through ongoing monthly patronage as a [GitHub Sponsor](https://github.com/sponsors/BlockchainCommons). You can also support Blockchain Commons with bitcoins at our [BTCPay Server](https://btcpay.blockchaincommons.com/).

## Contributing

We encourage public contributions through issues and pull requests! Please review [CONTRIBUTING.md](./CONTRIBUTING.md) for details on our development process. All contributions to this repository require a GPG signed [Contributor License Agreement](./CLA.md).

### Discussions

The best place to talk about Blockchain Commons and its projects is in our GitHub Discussions areas.

[**Gordian User Community**](https://github.com/BlockchainCommons/Gordian/discussions). For users of the Gordian reference apps, including [Gordian Coordinator](https://github.com/BlockchainCommons/iOS-GordianCoordinator), [Gordian Seed Tool](https://github.com/BlockchainCommons/GordianSeedTool-iOS), [Gordian Server](https://github.com/BlockchainCommons/GordianServer-macOS), [Gordian Wallet](https://github.com/BlockchainCommons/GordianWallet-iOS), and [SpotBit](https://github.com/BlockchainCommons/spotbit) as well as our whole series of [CLI apps](https://github.com/BlockchainCommons/Gordian/blob/master/Docs/Overview-Apps.md#cli-apps). This is a place to talk about bug reports and feature requests as well as to explore how our reference apps embody the [Gordian Principles](https://github.com/BlockchainCommons/Gordian#gordian-principles).

[**Blockchain Commons Discussions**](https://github.com/BlockchainCommons/Community/discussions). For developers, interns, and patrons of Blockchain Commons, please use the discussions area of the [Community repo](https://github.com/BlockchainCommons/Community) to talk about general Blockchain Commons issues, the intern program, or topics other than those covered by the [Gordian Developer Community](https://github.com/BlockchainCommons/Gordian-Developer-Community/discussions) or the 
[Gordian User Community](https://github.com/BlockchainCommons/Gordian/discussions).
### Other Questions & Problems

As an open-source, open-development community, Blockchain Commons does not have the resources to provide direct support of our projects. Please consider the discussions area as a locale where you might get answers to questions. Alternatively, please use this repository's [issues](https://github.com/BlockchainCommons/Bitcoin-Standup-Scripts/issues) feature. Unfortunately, we can not make any promises on response time.

If your company requires support to use our projects, please feel free to contact us directly about options. We may be able to offer you a contract for support from one of our contributors, or we might be able to point you to another entity who can offer the contractual support that you need.

### Credits

The following people directly contributed to this repository. You can add your name here by getting involved. The first step is learning how to contribute from our [CONTRIBUTING.md](./CONTRIBUTING.md) documentation.

| Name              | Role                | Github                                            | Email                                                       | GPG Fingerprint                                    |
| ----------------- | ------------------- | ------------------------------------------------- | ----------------------------------------------------------- | -------------------------------------------------- |
| Christopher Allen | Principal Architect | [@ChristopherA](https://github.com/ChristopherA) | \<ChristopherA@LifeWithAlacrity.com\>                       | FDFE 14A5 4ECB 30FC 5D22  74EF F8D3 6C91 3574 05ED |
| Peter Denton      | Project Lead        | [@Fonta1n3](https://github.com/Fonta1n3)          | <[fonta1n3@protonmail.com](mailto:fonta1n3@protonmail.com)> | 3B37 97FA 0AE8 4BE5 B440 6591 8564 01D7 121C 32FC  |

## Responsible Disclosure

We want to keep all of our software safe for everyone. If you have discovered a security vulnerability, we appreciate your help in disclosing it to us in a responsible manner. We are unfortunately not able to offer bug bounties at this time.

We do ask that you offer us good faith and use best efforts not to leak information or harm any user, their data, or our developer community. Please give us a reasonable amount of time to fix the issue before you publish it. Do not defraud our users or us in the process of discovery. We promise not to bring legal action against researchers who point out a problem provided they do their best to follow the these guidelines.

### Reporting a Vulnerability

Please report suspected security vulnerabilities in private via email to ChristopherA@BlockchainCommons.com (do not use this email for support). Please do NOT create publicly viewable issues for suspected security vulnerabilities.

The following keys may be used to communicate sensitive information to developers:

| Name              | Fingerprint                                        |
| ----------------- | -------------------------------------------------- |
| Christopher Allen | FDFE 14A5 4ECB 30FC 5D22  74EF F8D3 6C91 3574 05ED |

You can import a key by running the following command with that individual’s fingerprint: `gpg --recv-keys "<fingerprint>"` Ensure that you put quotes around fingerprints that contain spaces.
