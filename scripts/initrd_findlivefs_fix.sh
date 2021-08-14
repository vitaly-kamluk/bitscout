#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

UNPACKED_INITRD=0
if [ ! -d "./build.$GLOBAL_BASEARCH/initrd" ]
then
  statusprint "Unpacking initrd.."
  scripts/initrd_unpack.sh
  UNPACKED_INITRD=1
fi

if [ $GLOBAL_TARGET = "iso" ]; then
  statusprint "Fixing casper find_livefs method.."
  if [ -f "./build.$GLOBAL_BASEARCH/initrd/main/scripts/casper" ]
  then
    if ! grep -q "${PROJECTNAME}-${GLOBAL_BUILDID}" ./build.$GLOBAL_BASEARCH/initrd/main/scripts/casper
    then
      sudo sed -i 's/^\( *\)\(mount -t ${fstype} -o ro,noatime "${devname}" $mountpoint || return 1\)/\1blkid "${devname}" | grep -q "'"${PROJECTNAME}-${GLOBAL_BUILDID}"'" || return 1\n\1\2/' ./build.$GLOBAL_BASEARCH/initrd/main/scripts/casper
    fi
  fi
fi

if [ $UNPACKED_INITRD -eq 1 ]
then
  statusprint "Packing initrd.."
  scripts/initrd_pack.sh
  UNPACKED_INITRD=0
fi

exit 0;
