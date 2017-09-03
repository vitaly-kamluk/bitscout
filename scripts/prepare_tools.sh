#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Updating submodules.." &&
install_required_package git &&
git submodule init &&
git submodule update &&

statusprint "Patching apt-fast (reduce verbosity).." &&
( grep -q "^_DOWNLOADER='aria2c --console-log-level=warn" ./scripts/apt-fast/apt-fast || sed -i 's/^\(_DOWNLOADER='"'"'aria2c\)/\1 --console-log-level=warn/' ./scripts/apt-fast/apt-fast; exit 0 ) &&

statusprint "Patching apt-fast (force target platform to $BASEARCHITECTURE).." &&
( grep -q 'apt-get -y -o "APT::Architecture='$BASEARCHITECTURE'"' ./scripts/apt-fast/apt-fast || sed -i 's/apt-get -y.* --print-uris/apt-get -y -o "APT::Architecture='$BASEARCHITECTURE'" --print-uris/' ./scripts/apt-fast/apt-fast; exit 0 ) &&
( grep -q 'apt-cache -o "APT::Architecture='$BASEARCHITECTURE'"' ./scripts/apt-fast/apt-fast || sed -i 's/apt-cache.* show/apt-cache -o "APT::Architecture='$BASEARCHITECTURE'" show/' ./scripts/apt-fast/apt-fast; exit 0 ) &&

exit 0;
