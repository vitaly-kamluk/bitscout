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

if [ "$GLOBAL_CUSTOMKERNEL" == "1" ]
then
  statusprint "Installing write-blocker for casper.."
  cp -v ./resources/kernel/writeblocker/userspace/initramfs/01wrtblk_all initrd/scripts/casper-bottom/
fi

if [ $UNPACKED_INITRD -eq 1 ]
then
  statusprint "Packing initrd.."
  scripts/initrd_pack.sh
  UNPACKED_INITRD=0
fi


exit 0;
