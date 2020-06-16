# 🛠 Bitcoin-Standup Linux Scripts
This script installs the latest stable version of Tor, Bitcoin Core, Uncomplicated Firewall (UFW), Debian updates, enables automatic updates for Debian for good security practices, installs a random number generator, and optionally a QR encoder and an image displayer.

## Additional Information

For more information on *Bitcoin-Standup*:

1. The [Main *Bitcoin-Standup* Repo](https://github.com/BlockchainCommons/Bitcoin-Standup) contains general information on the project.
2. [Why Run a Full Node?](Docs/Why-Full.md) details why you would want to run a full node in the first place.
3. [Security for Bitcoin-Standup](Docs/Security) offers notes on ensuring the security of your *Bitcoin-Standup* node.

## Status — Work-in-Progress

*Bitcoin-Standup* is an early **Work-In-Progress**, so that we can prototype, discover additional requirements, and get feedback from the broader Bitcoin-Core Developer Community. ***It has not yet been peer-reviewed or audited. It is not yet ready for production uses. Use at your own risk.***

## Installation Instructions

There are two linux based StandUp scripts; `StandUp.sh` and `LinodeStandUp.sh`.

* `LinodeStandUp.sh` is built as a StackScript for the Linode platform and can be used as is. It's been tested on Debian 9 (Stretch) and Debian 10 (Buster).
* `StandUp.sh` can be used on a Debian VPS and has been tested on Debian 9 (Stretch) and Ubuntu 18.04.

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

   - Nano is a text editor that works in a terminal, you need to paste the entire contents of the [Standup script](Scripts/Standup.sh) into your terminal after running the above command. Then you can type:
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

The `LinodeStandup.sh` script is intended for use at [Linode.com](https://linode.com). You can find more precise information on using it from our [Learning Bitcoin from the Command Line course](https://github.com/BlockchainCommons/Learning-Bitcoin-from-the-Command-Line/blob/master/02_2_Setting_Up_a_Bitcoin-Core_VPS_with_StackScript.md). The following is a summary.

First, copy the `LinodeStandup.sh` script to your Linode:

1. Copy the complete [LinodeStandup.sh script](https://github.com/BlockchainCommons/Bitcoin-Standup-Scripts/blob/master/Scripts/LinodeStandUp.sh).
2. Go to the [Stackscripts page](https://cloud.linode.com/stackscripts?type=account) on your Linode account; choose [Create New Stackscript](https://cloud.linode.com/stackscripts/create)
3. Paste `LinodeStandup.sh` into the "Script" area. Make sure you got it all, from the "#!/bin/bash" to the "exit 1"!
4. Choose "Debian 10" (Buster) for the "Target Images".
5. Click "Save".

Second, create a node based on the script:

6. On the [Stackscripts page](https://cloud.linode.com/stackscripts?type=account), click on the "..." to the right of your new script and choose "Deploy New Linode".
7. Fill in a hostname and the password for the "standup" user.
8. Choose an Installation Type in your options. This is likely "Mainnet" or "Pruned Mainnet" if you are setting up a node for usage and "Pruned Testnet" if you're just playing around.
9. Fill in any other advanced options.
10. Choose a region for where the Linode will be located.
11. Choose a Linnode plan. Our general experience is that a Linode 8GB is needed to store the whole blockchain if you choose unpruned "Mainnet", while for testnet and the pruned options (and regtest) you'll instead be dependent on memory, where a Linode 4GB will definitely be sufficient, and a Linode 2GB has worked or not on various versions of Bitcoin Core. (If it fails, you'll get out-of-memory errors.)
12. Enter a root password.
13. Click "Create".

### Method Three: Install by Hand (Not Recommended)

Finally, if you prefer, you can install all of the packages for *Bitcoin-Standup* by hand. The  [Learning Bitcoin from the Command Line](https://github.com/ChristopherA/Learning-Bitcoin-from-the-Command-Line) course has [instructions on how to do so](https://github.com/ChristopherA/Learning-Bitcoin-from-the-Command-Line/blob/master/02_1_Setting_Up_a_Bitcoin-Core_VPS_by_Hand.md), but those methodologies will only install a full node, not include `tor` and not linking with the Quick Connect API. As such, this methodology is not recommended, but is simply included to provide you with the widest breadth of options.

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

## Financial Support

*Bitcoin-Standup* is a project of [Blockchain Commons](https://www.blockchaincommons.com/). We are proudly a "not-for-profit" social benefit corporation committed to open source & open development. Our work is funded entirely by donations and collaborative partnerships with people like you. Every contribution will be spent on building open tools, technologies, and techniques that sustain and advance blockchain and internet security infrastructure and promote an open web.

To financially support further development of *Bitcoin-Standup* and other projects, please consider becoming a Patron of Blockchain Commons through ongoing monthly patronage as a [GitHub Sponsor](https://github.com/sponsors/BlockchainCommons). You can also support Blockchain Commons with bitcoins at our [BTCPay Server](https://btcpay.blockchaincommons.com/).

## Contributing

We encourage public contributions through issues and pull requests! Please review [CONTRIBUTING.md](./CONTRIBUTING.md) for details on our development process. All contributions to this repository require a GPG signed [Contributor License Agreement](./CLA.md).

### Questions & Support

As an open-source, open-development community, Blockchain Commons does not have the resources to provide direct support of our projects. If you have questions or problems, please use this repository's [issues](./issues) feature. Unfortunately, we can not make any promises on response time.

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

## Reporting a Vulnerability

To report security issues send an email to ChristopherA@LifeWithAlacrity.com (not for support).

The following keys may be used to communicate sensitive information to developers:

| Name              | Fingerprint                                        |
| ----------------- | -------------------------------------------------- |
| Christopher Allen | FDFE 14A5 4ECB 30FC 5D22  74EF F8D3 6C91 3574 05ED |

You can import a key by running the following command with that individual’s fingerprint: `gpg --recv-keys "<fingerprint>"` Ensure that you put quotes around fingerprints that contain spaces.
