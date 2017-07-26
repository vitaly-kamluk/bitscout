#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Patching apt-fast.."
grep -q "^_DOWNLOADER='aria2c --console-log-level=warn" ./scripts/apt-fast/apt-fast || sed -i 's/^\(_DOWNLOADER='"'"'aria2c\)/\1 --console-log-level=warn/' ./scripts/apt-fast/apt-fast

exit 0;
