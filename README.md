# Witness-Mon
A [STEEM](https://github.com/steemit/steem) witness monitoring system to help prevent missed blocks. A system that parses the witness log, verifies normal operation and automatically disables the witness in case of detected errors. The system consist of one script for the witness node and one script for a remote monitoring node.

## Requirements
* This system has been tested in Ubuntu 16.04. But as it is all bash scripting it is safe to assume it works well in other environments.

* SMTP Client - Sending email notifications is an optional feature on both nodes. After installing an SMTP client, the feature needs to be enabled in the script. You need to be able to run something like this from the command line:
`echo "This is a message" | mail user@email.us`

### Requirements - Witness Node Specific

* The default settings for the Witness Node script (nodecheck.sh) is compatible with the [Steem-in-a-box](https://github.com/Someguy123/steem-docker) installation, but can easily be adjusted in the script's `#### CONFIGURATION SECTION ####`.

### Requirements - Monitoring Node Specific

* The Monitoring Node requires a witness tool, like [Conductor](https://github.com/Netherdrake/conductor) or [Beempy](https://github.com/holgern/beem), to be able to autonomously disable the STEEM witness. The default settings in the script is for Conductor, but same as above, it can easily be modified.

* SSH key login - The Monitoring Node needs to be able to login unattended to the Witness Node. SSH key login is the best way to achieve that.

* nc (netcat) - The Monitoring Node is using netcat to test Internet connectivity. I believe `nc` is installed by default in many distributions.



## Installation & Usage

### Witness Node
Default settings are for Steem-in-a-box:
* Make sure the requirements are met above.
* Place `nodecheck.sh` in the `steem-docker` folder.
* Make executable with `chmod +x nodecheck.sh`
* Adjust settings in the script's `#### CONFIGURATION SECTION ####`, enable email notifications etc.
* Run: `./nodecheck.sh`

### Monitoring Node
* Make sure the requirements are met above.
* Place `remotecheck.sh` in a folder of choice.
* Make executable with `chmod +x remotecheck.sh`
* Adjust settings in the script's `#### CONFIGURATION SECTION ####`. Important are the SSH connection string and the Conductor command line.
* When running `remotecheck.sh`, set the UNLOCK variable with the passphrase to unlock the wallet used by Conductor. For example, `UNLOCK=PHASSPHRASE ./remotecheck.sh`

#### By default, both scripts have this line `TESTING_MODE_ON=YES` in the `#### CONFIGURATION SECTION ####`. It will force the scripts in a test mode with all witness actions disabled. Comment that line to go live.

#### Utilise `systemd` or something similar to make both scripts persistent, to have them startup at boot.
