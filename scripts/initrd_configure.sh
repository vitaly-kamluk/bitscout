#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

INITRDDIR="./initrd"

#unpackinitrd

 ##statusprint "Setting hostname of the host system.."
 ##sed -i 's/HOST="[^"]*"/HOST="bitscout-host"/g; s/USERNAME="[^"]*"/USERNAME="user"/g; s/BUILD_SYSTEM="[^"]*"/BUILD_SYSTEM="Bitscout"/g;' "$INITRDDIR/etc/casper.conf"
 ##sed -i 's/^# export FLAVOUR="Ubuntu"/export FLAVOUR="Bitscout"/' "$INITRDDIR/etc/casper.conf"

 ##some more initrd changes.

#packinitrd
exit 0;
