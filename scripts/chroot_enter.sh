#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

CHROOTDIR=""
if [ $# -eq 0 ]; then 
  CHROOTDIR="build.$GLOBAL_BASEARCH/chroot"
else
  CHROOTDIR="$1"
fi

if [ ! -d "$CHROOTDIR" ]; then statusprint "Directory $CHROOTDIR doesn't exist."; exit 1; fi;
chroot_exec "$CHROOTDIR" "/bin/bash -i"
