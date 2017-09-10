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
install_required_package grub-efi-ia32
install_required_package grub-efi-amd64
install_required_package xorriso

sudo grub-mkrescue --modules="iso9660 linux ext2 fshelp ls boot jpeg video_bochs video_cirrus" --output=./$PROJECTNAME-16.04.iso ./image -- -r -volid "${PROJECTNAME}-${GLOBAL_BUILDID}" -partition_offset 16 -J -l -joliet-long -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -no-emul-boot # do not modify volid, it's critical for boot system!

exit 0;
