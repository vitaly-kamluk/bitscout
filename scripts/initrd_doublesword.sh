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

if [ "$GLOBAL_TARGET" != "iso" ]
then
  statusprint "Installing doublesword init script.."
  sudo cp -v ./resources/initrd/scripts/doublesword ./build.$GLOBAL_BASEARCH/initrd/main/scripts/
fi

if [ $UNPACKED_INITRD -eq 1 ]
then
  statusprint "Packing initrd.."
  scripts/initrd_pack.sh
  UNPACKED_INITRD=0
fi

exit 0;
