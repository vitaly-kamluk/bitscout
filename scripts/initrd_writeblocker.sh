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

statusprint "Installing write-blocker.."
sudo cp -v ./resources/usr/sbin/{wrtblk,wrtblk-disable,wrtblk-ioerr} ./build.$GLOBAL_BASEARCH/chroot/usr/sbin/

if [ $GLOBAL_TARGET = "iso" ]; then
  statusprint "Installing write-blocker to casper system.."
  sudo cp -v ./resources/initrd/scripts/casper-bottom/01wrtblk_all ./build.$GLOBAL_BASEARCH/initrd/main/scripts/casper-bottom/
  if ! grep "/scripts/casper-bottom/01wrtblk_all" ./build.$GLOBAL_BASEARCH/initrd/main/scripts/casper-bottom/ORDER; then
    sudo mv ./build.$GLOBAL_BASEARCH/initrd/main/scripts/casper-bottom/ORDER ./build.$GLOBAL_BASEARCH/initrd/main/scripts/casper-bottom/ORDER.old &&
    ( echo -e '/scripts/casper-bottom/01wrtblk_all "$@"\n[ -e /conf/param.conf ] && . /conf/param.conf'; cat ./build.$GLOBAL_BASEARCH/initrd/main/scripts/casper-bottom/ORDER.old ) | sudo tee ./build.$GLOBAL_BASEARCH/initrd/main/scripts/casper-bottom/ORDER > /dev/null &&
    sudo rm ./build.$GLOBAL_BASEARCH/initrd/main/scripts/casper-bottom/ORDER.old
  fi
else
  statusprint "Installing write-blocker to doublesword system.."
  [ ! -d "./build.$GLOBAL_BASEARCH/initrd/main/scripts/doublesword-bottom/" ] && sudo mkdir -p ./build.$GLOBAL_BASEARCH/initrd/main/scripts/doublesword-bottom/ 
  sudo cp -v ./resources/initrd/scripts/doublesword-bottom/01wrtblk_all ./build.$GLOBAL_BASEARCH/initrd/main/scripts/doublesword-bottom/
fi

if [ $UNPACKED_INITRD -eq 1 ]
then
  statusprint "Packing initrd.."
  scripts/initrd_pack.sh
  UNPACKED_INITRD=0
fi


exit 0;
