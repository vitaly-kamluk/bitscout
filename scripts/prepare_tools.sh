#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Patching apt-fast (reduce verbosity).."
grep -q "^_DOWNLOADER='aria2c --console-log-level=warn" ./scripts/apt-fast/apt-fast || sed -i 's/^\(_DOWNLOADER='"'"'aria2c\)/\1 --console-log-level=warn/' ./scripts/apt-fast/apt-fast

statusprint "Patching apt-fast (force target platform to $BASEARCHITECTURE).."
grep -q 'apt-get -y -o "APT::Architecture='$BASEARCHITECTURE'"' ./scripts/apt-fast/apt-fast || sed -i 's/apt-get -y --print-uris/apt-get -y -o "APT::Architecture='$BASEARCHITECTURE'" --print-uris/' ./scripts/apt-fast/apt-fast
grep -q 'apt-cache -o "APT::Architecture='$BASEARCHITECTURE'"' ./scripts/apt-fast/apt-fast || sed -i 's/apt-cache show/apt-cache -o "APT::Architecture='$BASEARCHITECTURE'" show/' ./scripts/apt-fast/apt-fast


exit 0;
