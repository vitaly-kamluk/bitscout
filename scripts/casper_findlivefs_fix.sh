#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

UNPACKED_INITRD=0
if [ ! -d "initrd" ]
then
  statusprint "Unpacking initrd.."
  scripts/initrd_unpack.sh
  UNPACKED_INITRD=1
fi

statusprint "Fixing casper find_livefs method.."
if [ -f "initrd/scripts/casper" ]
then
  if ! grep -q "${PROJECTNAME}-${GLOBAL_BUILDID}" initrd/scripts/casper
  then
    sed -i 's/^\( *\)\(mount -t ${fstype} -o ro,noatime "${devname}" $mountpoint || continue\)/\1blkid "${devname}" | grep -q "'"${PROJECTNAME}-${GLOBAL_BUILDID}"'" || continue\n\1\2/' initrd/scripts/casper
  fi
fi

if [ $UNPACKED_INITRD -eq 1 ]
then
  statusprint "Packing initrd.."
  scripts/initrd_pack.sh
  UNPACKED_INITRD=0
fi

exit 0;
