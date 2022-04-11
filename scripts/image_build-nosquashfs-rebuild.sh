#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Calculating files MD5 for integrity control.."
cd image && find . -type f -print0 | xargs -0 sudo md5sum | grep -v "\./md5sum.txt" > md5sum.txt
cd ..

statusprint "Creating grub-powered image..."
install_required_package grub-common
install_required_package grub-pc-bin
install_required_package grub-efi-ia32-bin
install_required_package grub-efi-amd64-bin
install_required_package mtools
install_required_package xorriso

if grub-mkrescue --output=/dev/null -- -as mkisofs 2>&1 | grep -q "FAILURE : -as mkisofs"
then
  #worked while building on ubuntu 16.04
  sudo grub-mkrescue --modules="iso9660 linux ext2 fshelp ls boot jpeg video_bochs video_cirrus" --output=./$PROJECTNAME-22.04.iso ./image -- -r -volid "${PROJECTNAME}-${GLOBAL_BUILDID}" -partition_offset 16 -J -l -joliet-long -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -no-emul-boot # do not modify volid, it's critical to system boot
else
  #worked while building on ubuntu 17.10
  sudo grub-mkrescue --modules="iso9660 linux ext2 fshelp ls boot jpeg video_bochs video_cirrus" --output=./$PROJECTNAME-22.04.iso ./image -- -as mkisofs -r -volid "${PROJECTNAME}-${GLOBAL_BUILDID}" -partition_offset 16 -J -l -joliet-long -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -no-emul-boot # do not modify volid, it's critical to system boot
fi

exit 0;
