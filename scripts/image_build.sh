#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

install_required_package squashfs-tools

statusprint "Compressing chroot.."
SQUASHFSIMG="image/casper/filesystem.squashfs"
if [ -f "$SQUASHFSIMG" ]
then
 sudo rm -f "$SQUASHFSIMG"
fi

printf $(sudo du -sx --block-size=1 chroot | cut -f1) | sudo tee image/casper/filesystem.size >/dev/null

statusprint "Making squashfs image.."
sudo mksquashfs chroot "$SQUASHFSIMG" -e boot 

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
  sudo grub-mkrescue --modules="part_gpt iso9660 linux ext2 fshelp ls boot jpeg video_bochs video_cirrus" --output=./$PROJECTNAME-18.04.iso ./image -- -r -volid "${PROJECTNAME}-${GLOBAL_BUILDID}" -partition_offset 16 -J -l -joliet-long -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -no-emul-boot
else
  #worked while building on ubuntu 17.10
  sudo grub-mkrescue --modules="part_gpt iso9660 linux ext2 fshelp ls boot jpeg video_bochs video_cirrus" --output=./$PROJECTNAME-18.04.iso ./image -- -as mkisofs -r -volid "${PROJECTNAME}-${GLOBAL_BUILDID}" -partition_offset 16 -J -l -joliet-long -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -no-emul-boot
fi

exit 0;
