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

statusprint "Installing boot-phase write-blocker.."
if [ $GLOBAL_TARGET = "iso" ]; then
  sudo cp -v ./resources/initrd/scripts/casper-bottom/01wrtblk_all ./build.$GLOBAL_BASEARCH/initrd/main/scripts/casper-bottom/
else
  [ ! -d "./build.$GLOBAL_BASEARCH/initrd/main/scripts/doublesword-bottom/" ] && sudo mkdir -p ./build.$GLOBAL_BASEARCH/initrd/main/scripts/doublesword-bottom/ 
  sudo cp -v ./resources/initrd/doublesword-bottom/01wrtblk_all ./build.$GLOBAL_BASEARCH/initrd/main/scripts/doublesword-bottom/
fi

if [ $UNPACKED_INITRD -eq 1 ]
then
  statusprint "Packing initrd.."
  scripts/initrd_pack.sh
  UNPACKED_INITRD=0
fi


exit 0;
