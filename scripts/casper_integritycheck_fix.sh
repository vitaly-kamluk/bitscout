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


statusprint "Replacing casper-md5check with own.."
#currently casper-md5check doesn't work without plymouth
if [ ! -f "./build.$GLOBAL_BASEARCH/initrd/main/bin/casper-md5check.dist" ]
then
  mv ./build.$GLOBAL_BASEARCH/initrd/main/bin/casper-md5check ./build.$GLOBAL_BASEARCH/initrd/main/bin/casper-md5check.dist
fi
cp -v ./build.$GLOBAL_BASEARCH/chroot/usr/bin/md5sum ./build.$GLOBAL_BASEARCH/initrd/main/bin/md5sum
cp -v resources/casper/bin/casper-md5check ./build.$GLOBAL_BASEARCH/initrd/main/bin/casper-md5check
chmod +x ./build.$GLOBAL_BASEARCH/initrd/main/bin/casper-md5check

statusprint "Fixing I/O redirection for the script.."
sed -i 's,\(casper-md5check .*md5sum.txt \)< /dev/tty8 > /dev/tty8,\1,' ./build.$GLOBAL_BASEARCH/initrd/main/scripts/casper-bottom/01integrity_check


if [ $UNPACKED_INITRD -eq 1 ]
then
  statusprint "Packing initrd.."
  scripts/initrd_pack.sh
  UNPACKED_INITRD=0
fi


exit 0;
