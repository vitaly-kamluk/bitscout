#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Unpacking initrd.."
./scripts/initrd_unpack.sh

statusprint "Replacing casper-md5check with own.."
#currently casper-md5check doesn't work without plymouth
if [ ! -f "initrd/bin/casper-md5check.dist" ]
then
  mv initrd/bin/casper-md5check initrd/bin/casper-md5check.dist
fi
cp -v ./chroot/usr/bin/md5sum initrd/bin/md5sum
cp -v resources/casper/bin/casper-md5check initrd/bin/casper-md5check
chmod +x initrd/bin/casper-md5check

statusprint "Fixing I/O redirection for the script.."
sed -i 's,\(casper-md5check .*md5sum.txt \)< /dev/tty8 > /dev/tty8,\1,' initrd/scripts/casper-bottom/01integrity_check


statusprint "Compressing initrd.."
./scripts/initrd_pack.sh

exit 0;
