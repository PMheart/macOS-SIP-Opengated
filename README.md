openGate.sh
============

As we all know. Apple introduced SIP (System Integrity Protection) in OS X El Capitan. And it got enhanced in macOS Sierra. Pretty good. But in some cases we have to change the settings of SIP. And Apple set a restriction that we cannot configure SIP under normal OS. We cannot set SIP status via ```csrutil```.
So that's why I wrote this script.

With the help of this script, we can patch AppleEFINVRAM.kext in ```/System/Library/Extensions/AppleEFIRuntime.kext/Contents/PlugIns/AppleEFINVRAM.kext``` and then this make configuring SIP status possible under normal OS X/macOS.

How to use openGate.sh?
------------------------
Download the latest openGate.sh by entering the following command in a terminal window:

``` sh
curl -O https://raw.githubusercontent.com/PMheart/macOS-SIP-Opengated/master/openGate.sh
```

This will download openGate.sh to your current directory (./) and the next step is to change the permissions of the file (add +x) so that it can be run.

``` sh
chmod +x ./openGate.sh
```

Run the script in a terminal window by:

``` sh
./openGate.sh
```

Change Log
----------------
11/12/2016
- Initial commit.
