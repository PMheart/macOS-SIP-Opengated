#!/bin/bash

#
# Script (openGate.sh) to enable configuring SIP (System Integrity Protection) under normal OS.
#
#
# Version 0.2 - Copyright (c) 2013-2016 by Angel W.
#
# Updates:
#                   - A possibility to uninstall/revert everything back. (Angel W. , December 2016)
#

# set -x # Used for tracing errors (can be used anywhere in the script).
sudo -k  # Kill root privilege at a glance to prevent errors.

#================================= GLOBAL VARS ==================================

#
# Script version info.
#
gScriptVersion=0.2

#
# The script expects '0.5' but non-US localizations use '0,5' so we export
# LC_NUMERIC here (for the duration of the openGate.sh) to prevent errors.
#
export LC_NUMERIC="en_US.UTF-8"

#
# Get user id
#
let gID=$(id -u)

#
# Initialize variable with the Extensions directory.
#
gExtensionsDirectory=("/System/Library/Extensions" "/Library/Extensions")

#
# The location of AppleEFINVRAM.kext
#
gEFINVRAMDirectory="${gExtensionsDirectory[0]}/AppleEFIRuntime.kext/Contents/PlugIns/AppleEFINVRAM.kext"

#
# The version info of the running system e.g. '10.12.1'
#
gProductVersion="$(sw_vers -productVersion)"

#
# The build info of the running system e.g. '16B2657'
#
gBuildVersion="$(sw_vers -buildVersion)"

#
# PlistBuddy Command Line Tool location.
#
gPlistBuddyCLT="/usr/libexec/PlistBuddy -c"

#
# Output styling.
#
STYLE_BOLD="[1m"
STYLE_RESET="[0m"


#
#--------------------------------------------------------------------------------
#


function _printHeader()
{
  printf "\n${STYLE_BOLD}openGate.sh${SYTLE_RESET} v${gScriptVersion} Copyright (c) $(date "+%Y") by Angel W.\n"
  echo '----------------------------------------------------------------'
  printf "Running on ${gProductVersion} (${gBuildVersion})\n\n"
}


#
#--------------------------------------------------------------------------------
#


function SearchAndCount()
{
  local byteValue=$1
  local byteValueEncode=$(echo $byteValue | sed 's/.\{2\}/\\\x&/g')
  local extBin=$2
  perl -le "print scalar grep /$byteValueEncode/, <>;" "$extBin"
}


#
#--------------------------------------------------------------------------------
#


function SearchAndReplace()
{
  local byteValueSearch=$1
  local byteValueSearchEncode=$(echo $byteValueSearch | sed 's/.\{2\}/\\\x&/g')
  local byteValueReplace=$2
  local byteValueReplaceEncode=$(echo $byteValueReplace | sed 's/.\{2\}/\\\x&/g')
  local targetBin=$3
  perl -pi -e "s|$byteValueSearchEncode|$byteValueReplaceEncode|g" "$targetBin"
}


#
#--------------------------------------------------------------------------------
#


function _install_kext()
{
  local kextName=$1

  #
  # Copy to /Library/Extensions
  #
  cp -RX "$kextName" "${gExtensionsDirectory[1]}"
  #
  # Set permissions.
  #
  chmod -R 755 "${gExtensionsDirectory[1]}"
  chown -R 0:0 "${gExtensionsDirectory[1]}"
  #
  # Rebuild caches.
  #
  printf 'Rebuilding caches...'
  touch "${gExtensionsDirectory[0]}"
  touch "${gExtensionsDirectory[1]}"
  kextcache -u /&>/dev/null
}


#
#--------------------------------------------------------------------------------
#


function _check_data()
{

  #
  # We can't rely on system build info to determine the current AppleEFINVRAM version.
  # Because in some cases we may use a different version of AppleEFINVRAM.
  # We will use "brute-force" method - just try to patch.
  #

  if [[ `SearchAndCount "0f85fe000000" "$gEFINVRAMDirectory/Contents/MacOS/AppleEFINVRAM"` == 1 ]];
    #
    # Yosemite _mac_iokit_check_nvram_set found.
    #
    then
      #
      # Check further.
      #
      if [[ `SearchAndCount "7541eb5c" "$gEFINVRAMDirectory/Contents/MacOS/AppleEFINVRAM"` == 1 ]];
        #
        # Yosemite _mac_iokit_check_nvram_delete found.
        #
        then
          printf '==> AppleEFINVRAM Yosemite version found.\n'
      fi
    elif [[ `SearchAndCount "85c00f8540010000" "$gEFINVRAMDirectory/Contents/MacOS/AppleEFINVRAM"` == 1 ]];
      #
      # El Capitan _mac_iokit_check_nvram_set found.
      #
      then
        #
        # Check further.
        #
        if [[ `SearchAndCount "85c0740b4883c408" "$gEFINVRAMDirectory/Contents/MacOS/AppleEFINVRAM"` == 1 ]];
          #
          # El Capitan _mac_iokit_check_nvram_delete found.
          #
          then
            printf '==> AppleEFINVRAM El Capitan version found.\n'
        fi
    elif [[ `SearchAndCount "85c00f8549010000" "$gEFINVRAMDirectory/Contents/MacOS/AppleEFINVRAM"` == 1 ]];
      #
      # Sierra _mac_iokit_check_nvram_set found.
      #
      then
        #
        # Check further.
        #
        if [[ `SearchAndCount "85c0740b4883" "$gEFINVRAMDirectory/Contents/MacOS/AppleEFINVRAM"` == 1 ]];
          #
          # Sierra _mac_iokit_check_nvram_delete found.
          #
          then
            printf '==> AppleEFINVRAM Sierra version found.\n'
        fi
    else
      #
      # Nothing found. Aborting...
      #
      printf 'Your AppleEFINVRAM may be broken or patched already!\n'
      exit 1
  fi
}


#
#--------------------------------------------------------------------------------
#


function _make_injector()
{
  #
  # Copy vanilla AppleEFINVRAM.kext to /tmp/LegacyEFINVRAM.kext
  #
  cp -RX "$gEFINVRAMDirectory" /tmp/LegacyEFINVRAM.kext

  #
  # Change working directory to /tmp/LegacyEFINVRAM.kext/Contents
  #
  cd /tmp/LegacyEFINVRAM.kext/Contents

  #
  # Remove something we don't want (redundant files).
  #
  rm -R ./Resources ./_CodeSignature ./version.plist

  #
  # Patch Info.plist so that our injector can work. (To increase bundle version.)
  #
  printf 'Patching Info.plist...\n'
  $gPlistBuddyCLT "Delete ':BuildMachineOSBuild'" ./Info.plist
  $gPlistBuddyCLT "Set ':CFBundleShortVersionString' 999.99.9" ./Info.plist
  $gPlistBuddyCLT "Delete ':CFBundleSupportedPlatforms'" ./Info.plist
  $gPlistBuddyCLT "Set ':CFBundleVersion' 999.99.9" ./Info.plist
  $gPlistBuddyCLT "Delete ':DTCompiler'" ./Info.plist
  $gPlistBuddyCLT "Delete ':DTPlatformBuild'" ./Info.plist
  $gPlistBuddyCLT "Delete ':DTPlatformVersion'" ./Info.plist
  $gPlistBuddyCLT "Delete ':DTSDKBuild'" ./Info.plist
  $gPlistBuddyCLT "Delete ':DTSDKName'" ./Info.plist
  $gPlistBuddyCLT "Delete ':DTXcode'" ./Info.plist
  $gPlistBuddyCLT "Delete ':DTXcodeBuild'" ./Info.plist

  #
  # Patch AppleEFINVRAM binary based on the output of _check_data()
  #
  if [[ `_check_data` == *"Yosemite"* ]];
    #
    # Detected Yosemite version.
    #
    then
      #
      # Patch _mac_iokit_check_nvram_set
      #
      SearchAndReplace "0f85fe000000" "90e9fe000000" /tmp/LegacyEFINVRAM.kext/Contents/MacOS/AppleEFINVRAM
      printf 'Yosemite _mac_iokit_check_nvram_set patched.\n'
      #
      # Patch _mac_iokit_check_nvram_delete
      #
      SearchAndReplace "7541eb5c" "eb41eb5c" /tmp/LegacyEFINVRAM.kext/Contents/MacOS/AppleEFINVRAM
      printf 'Yosemite _mac_iokit_check_nvram_delete patched.\n'
    elif [[ `_check_data` == *"El Capitan"* ]];
      #
      # Detected El Capitan version.
      #
      then
        #
        # Patch _mac_iokit_check_nvram_set
        #
        SearchAndReplace "85c00f8540010000" "85c0909090909090" /tmp/LegacyEFINVRAM.kext/Contents/MacOS/AppleEFINVRAM
        printf 'El Capitan _mac_iokit_check_nvram_set patched.\n'
        #
        # Patch _mac_iokit_check_nvram_delete
        #
        SearchAndReplace "85c0740b4883c408" "85c0eb0b4883c408" /tmp/LegacyEFINVRAM.kext/Contents/MacOS/AppleEFINVRAM
        printf 'El Capitan _mac_iokit_check_nvram_delete patched.\n'
    elif [[ `_check_data` == *"Sierra"* ]];
      #
      # Detected Sierra version.
      #
      then
        #
        # Patch _mac_iokit_check_nvram_set
        #
        SearchAndReplace "85c00f8549010000" "85c0909090909090" /tmp/LegacyEFINVRAM.kext/Contents/MacOS/AppleEFINVRAM
        printf 'Sierra _mac_iokit_check_nvram_set patched.\n'
        #
        # Patch _mac_iokit_check_nvram_delete
        #
        SearchAndReplace "85c0740b4883" "85c0eb0b4883" /tmp/LegacyEFINVRAM.kext/Contents/MacOS/AppleEFINVRAM
        printf 'Sierra _mac_iokit_check_nvram_delete patched.\n'
  fi

  #
  # Go back to default working directory.
  #
  cd
}


#
#--------------------------------------------------------------------------------
#


function main()
{
  _printHeader
  #
  # We should check system version at a glance.
  #
  gOSVersion=$(sw_vers -productVersion | awk -F '.' '{print $1 "." $2}')

  case $gOSVersion in
  10.10 | 10.11 | 10.12 ) #
                          # Supported OS detected. Then do nothing.
                          #
                          ;;
  *                     ) printf "Your system version (`gOSVersion`.x) is not supported!"
                          exit 1
                          ;;
  esac

  #
  # To unistall patched AppleEFINVRAM.kext (LegacyEFINVRAM.kext)
  #
  gArgv=$(echo "$@" | tr '[:lower:]' '[:upper:]')
  if [[ "$gArgv" == *"-U"* ]];
    then
      printf 'Uninstalling /Library/Extensions/LegacyEFINVRAM.kext...\n'
      rm -Rf /Library/Extensions/LegacyEFINVRAM.kext
      #
      # Fix permissions.
      #
      chmod -R 755 "${gExtensionsDirectory[1]}"
      chown -R 0:0 "${gExtensionsDirectory[1]}"
      #
      # Rebuild caches.
      #
      touch "${gExtensionsDirectory[0]}"
      touch "${gExtensionsDirectory[1]}"
      kextcache -u /&>/dev/null
      printf 'Uninstalled. Please restart the machine for the changes to take effect.\n'
      exit 0
  fi

  _check_data
  #
  # We should remove previous files before making injector.
  #
  rm -Rf /tmp/LegacyEFINVRAM.kext

  _make_injector

  #
  # Install /tmp/LegacyEFINVRAM.kext to /Library/Extensions
  #
  _install_kext "/tmp/LegacyEFINVRAM.kext"

  #
  # Okay. All done. Now about to exit.
  #
  printf 'All done! Now SIP got open-gated. Enjoy!\n'
}

#==================================== START =====================================

clear

if [[ $gID -eq 0 ]];
  then
    #
    # We are root. Call main with arguments.
    #
    main "$@"
  else
    echo "This script ${STYLE_UNDERLINED}must${STYLE_RESET} be run as root!" 1>&2\
    #
    # Re-run script with arguments.
    #
    sudo "$0" "$@"
fi

#================================================================================

exit 0
