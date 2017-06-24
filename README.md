openGate.sh
============

### 10.13 announcements
--------------------
Now this serious bug has been fixed! Thanks Apple. So this script won't work under macOS `High Sierra`.

Introduction
-------------
As we all know. Apple introduced SIP (System Integrity Protection) in OS X El Capitan. And it got enhanced in macOS Sierra. Pretty good. But in some cases we have to change the settings of SIP. And Apple set a restriction that we cannot configure SIP under normal OS. We cannot set SIP status via ```csrutil```.

So that's why I wrote this script.

With the help of this script, we can patch AppleEFINVRAM.kext in ```/System/Library/Extensions/AppleEFIRuntime.kext/Contents/PlugIns/AppleEFINVRAM.kext``` and then this make configuring SIP status possible under normal OS X/macOS.

Note: You should use root privilege instead of normal privilege under normal OS if you want to configure SIP.
``` sh
sudo csrutil <args>
```

How to use openGate.sh?
------------------------
Download the latest openGate.sh by entering the following command in a terminal window:

``` sh
curl -o ./openGate.sh https://raw.githubusercontent.com/PMheart/macOS-SIP-Opengated/master/openGate.sh
```

This will download openGate.sh to your current directory (./) and the next step is to change the permissions of the file (add +x) so that it can be run.

``` sh
chmod +x ./openGate.sh
```

Run the script in a terminal window by:

``` sh
./openGate.sh
```

Also. You can uninstall what the script did by:
``` sh
./openGate.sh -u
```

References
------------
https://www.idelta.info/archives/os-x-nvram-restriction-bypassed
https://pikeralpha.wordpress.com/2015/09/23/another-one-bites-the-dust/

Change Log
----------------
01/28/2016
- 10.12.4+ compatibility.

12/12/2016
- Only patch after the search data has been found.
- If /Library/Extensions/LegacyEFINVRAM.kext found then determine whether to re-install by user.

11/12/2016
- Initial commit.
- A possibility to uninstall patched AppleEFINVRAM.kext/LegacyEFINVRAM.kext


Bug Reporting
---------------
All bugs should be filed [here] (https://github.com/PMheart/macOS-SIP-Opengated/issues).
