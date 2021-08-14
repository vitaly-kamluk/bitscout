#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Making sure package cache and other fs are detached.."
chroot_unmount_fs "./build.$GLOBAL_BASEARCH/chroot"

install_required_package grub-common
install_required_package grub-pc-bin
install_required_package grub-efi-ia32-bin
install_required_package grub-efi-amd64-bin


if [ "$GLOBAL_TARGET" = "iso" ]; then
  statusprint "Preparing to build an ISO image.."
  install_required_package squashfs-tools

  statusprint "Compressing chroot.."
  SQUASHFSIMG="./build.$GLOBAL_BASEARCH/image/casper/filesystem.squashfs"
  if [ -f "$SQUASHFSIMG" ]
  then
   sudo rm -f "$SQUASHFSIMG"
  fi

  printf $(sudo du -sx --block-size=1 "build.$GLOBAL_BASEARCH" | cut -f1) | sudo tee ./build.$GLOBAL_BASEARCH/image/casper/filesystem.size >/dev/null

  statusprint "Making squashfs image.."
  sudo mksquashfs ./build.$GLOBAL_BASEARCH/chroot "$SQUASHFSIMG" -e boot -wildcards -ef ./resources/squashfs/exclude.list 

  statusprint "Calculating files MD5 for integrity control.."
  cd ./build.$GLOBAL_BASEARCH/image && find . -type f -print0 | xargs -0 sudo md5sum | grep -v "\./md5sum.txt" > md5sum.txt
  cd ../../

  statusprint "Creating grub-powered image..."
  install_required_package mtools
  install_required_package xorriso

  sudo grub-mkrescue --modules="part_gpt iso9660 linux ext2 fshelp ls boot jpeg video_bochs video_cirrus" --output=./$PROJECTNAME-$PROJECTRELEASE-$GLOBAL_BASEARCH.iso ./build.$GLOBAL_BASEARCH/image -- -as mkisofs -r -volid "${PROJECTNAME}-${GLOBAL_BUILDID}" -J -l -joliet-long -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -no-emul-boot

elif [ "$GLOBAL_TARGET" = "raw" ]; then
  statusprint "Preparing to build a raw disk image.."
  install_required_package gdisk

  BIOSGRUB_START_MB=1
  BIOSGRUB_SIZE_MB=1

  EFIPART_START_MB=$[$BIOSGRUB_START_MB + $BIOSGRUB_SIZE_MB]
  EFIPART_SIZE_MB=128

  ROOTPART_START_MB=$[$EFIPART_START_MB + $EFIPART_SIZE_MB]
  ROOTPART_SIZE_MB=$( sudo du -B $[1024*1024] -s ./build.$GLOBAL_BASEARCH/chroot/ 2>&1 | awk '{ print $1 + 256}' )

  PERSPART_START_MB=$[ $ROOTPART_START_MB + $ROOTPART_SIZE_MB ]
  PERSPART_SIZE_B=$( normalize_size $GLOBAL_PERSISTSIZE )
  PERSPART_SIZE_MB=$( awk '{print $0/(1024*1024)}' <<< $PERSPART_SIZE_B )

  IMG_SIZE_MB=$[$PERSPART_START_MB+$PERSPART_SIZE_MB+1]
  IMG_SIZE_B=$[$IMG_SIZE_MB*1024*1024]
  IMGFILE=$PROJECTNAME-$PROJECTRELEASE-$GLOBAL_BASEARCH.$GLOBAL_TARGET

  statusprint "Target disk image size: $IMG_SIZE_B bytes"
  [ -f "./$IMGFILE" ] && rm -f "./$IMGFILE" 2>&1
  truncate -s $IMG_SIZE_B "./$IMGFILE"
  if [ ! -f "./$IMGFILE" ]; then statusprint "Failed to create image file at $IMGFILE"; exit 1; fi; 

  statusprint "Building hybrid MSDOS/GPT partition table.."
  sgdisk -h "./$IMGFILE"
  sgdisk -n 1::+${BIOSGRUB_SIZE_MB}M -t 1:EF02 -n 2::+${EFIPART_SIZE_MB}M -t 2:EF00 -n 3::+${ROOTPART_SIZE_MB}M -t 3:8300 -n 4::+${PERSPART_SIZE_MB}M -t 4:8300 "./$IMGFILE"

  statusprint "Preparing loop devices.."
  LOOPDEV_IMG=$(sudo losetup -f)
  if [ ! -b ${LOOPDEV_IMG} ]; then statusprint "Couldn't find spare loop device for the image.."; exit 1; fi;
  sudo losetup --partscan ${LOOPDEV_IMG} "./$IMGFILE"

  LOOPDEV_PART_BIOS_GRUB=${LOOPDEV_IMG}p1
  LOOPDEV_PART_EFI=${LOOPDEV_IMG}p2
  LOOPDEV_PART_ROOT=${LOOPDEV_IMG}p3
  LOOPDEV_PART_PERS=${LOOPDEV_IMG}p4

  #statusprint "Formatting boot partition.."
  #sudo mkfs -q -t ext2 -d ./build.${GLOBAL_BASEARCH}/chroot/boot -F -e remount-ro -L /boot -U random $LOOPDEV_PART_BOOT

  statusprint "Formatting EFI partition.."
  sudo mkfs.fat -F32 -n EFI $LOOPDEV_PART_EFI

  statusprint "Formatting and populating root partition.."
  sudo mkfs -q -t ext4 -d ./build.${GLOBAL_BASEARCH}/chroot -F -e remount-ro -L / -U random $LOOPDEV_PART_ROOT

  statusprint "Formatting and populating persistence partition.."
  sudo mkfs -q -t ext4 -d ./resources/persistence -F -L /persistence -U random $LOOPDEV_PART_PERS

  statusprint "Getting root partition UUID.."
  PART_ROOT_UUID=$(sudo blkid -o udev ${LOOPDEV_PART_ROOT} | awk -F= '/ID_FS_UUID=/{print $2}')

  statusprint "Getting persistence partition UUID.."
  PART_PERS_UUID=$(sudo blkid -o udev ${LOOPDEV_PART_PERS} | awk -F= '/ID_FS_UUID=/{print $2}')

  statusprint "Mounting target image rootfs.."
  sudo mount -t ext4 ${LOOPDEV_PART_ROOT} ./build.${GLOBAL_BASEARCH}/image

  #statusprint "Mounting boot partition.."
  #sudo rm -rf ./build.${GLOBAL_BASEARCH}/image/boot
  #[ ! -d "./build.${GLOBAL_BASEARCH}/image/boot" ] && sudo mkdir -p ./build.${GLOBAL_BASEARCH}/image/boot
  #sudo mount -t ext4 ${LOOPDEV_PART_BOOT} ./build.${GLOBAL_BASEARCH}/image/boot

  statusprint "Mounting EFI partition.."
  [ ! -d "./build.${GLOBAL_BASEARCH}/image/boot/efi" ] && sudo mkdir -p ./build.${GLOBAL_BASEARCH}/image/boot/efi
  sudo mount -t vfat ${LOOPDEV_PART_EFI} ./build.${GLOBAL_BASEARCH}/image/boot/efi

  statusprint "Mounting persistence partition.."
  sudo mount -t ext4 ${LOOPDEV_PART_PERS} ./build.${GLOBAL_BASEARCH}/image/persistence

  statusprint "Fixing ownership on persistence partition.."
  sudo chown root:root ./build.${GLOBAL_BASEARCH}/image/persistence/host ./build.${GLOBAL_BASEARCH}/image/persistence/container

  statusprint "Unmounting persistence filesystem.."
  sudo umount ./build.${GLOBAL_BASEARCH}/image/persistence

  PROJDIR=$PWD
  statusprint "Adding target loop devices to the mounted rootfs.."
  pushd /dev >/dev/null
  tar -cpf- ${LOOPDEV_IMG##*/} ${LOOPDEV_PART_BOOT##*/} ${LOOPDEV_PART_EFI##*/} ${LOOPDEV_PART_ROOT##*/} ${LOOPDEV_PART_PERS##*/} | sudo tar -xf- -C $PROJDIR/build.$GLOBAL_BASEARCH/image/dev
  popd >/dev/null

  if [ ! -b "./build.$GLOBAL_BASEARCH/image/dev/${LOOPDEV_IMG##*/}" ]; then 
    statusprint "Couldn't find loop device on the target rootfs."; 
    sudo umount ./build.$GLOBAL_BASEARCH/image/boot/efi ./build.$GLOBAL_BASEARCH/image/boot ./build.$GLOBAL_BASEARCH/image
    sudo losetup -d $LOOPDEV_IMG
    exit 1; 
  fi;

  statusprint "Copying boot configuration from resources.."
  sudo cp -rv ./resources/boot/* ./build.$GLOBAL_BASEARCH/image/boot/
  sudo sed -i "s/<PROJECTNAME>/${PROJECTNAME}/g; s/<PROJECTCAPNAME>/${PROJECTCAPNAME}/g; s/<PROJECTSHORTNAME>/${PROJECTSHORTNAME}/g; s/<CONTAINERUSERNAME>/${CONTAINERUSERNAME}/g; s/<PROJECTRELEASE>/${PROJECTRELEASE}/g; s#/casper/#/boot/#g; s/boot=casper/boot=doublesword root=UUID=$PART_ROOT_UUID persist=UUID=$PART_PERS_UUID/" ./build.$GLOBAL_BASEARCH/image/boot/grub/grub.cfg

  statusprint "Altering boot splash image.."
  install_required_package imagemagick
  sudo convert -quiet ./build.$GLOBAL_BASEARCH/image/boot/grub/theme/background.jpg +repage ./build.$GLOBAL_BASEARCH/image/boot/grub/theme/background.tiff
  sudo convert ./build.$GLOBAL_BASEARCH/image/boot/grub/theme/background.tiff \( -clone 0 -fill srgb\(255,255,255\) -colorize 100% -modulate 100,100,100 \) \( -clone 0 -blur 0x1 -fuzz 10% -fill none -draw "matte 580,630 floodfill" -channel rgba -fill black +opaque none -fill white -opaque none -blur 0x8 -auto-level -evaluate multiply 1 \) -compose over -composite -pointsize 22 -font /usr/share/fonts/truetype/ubuntu/Ubuntu-B.ttf -fill rgba\(255,255,255,0.8\) -annotate +750+580 20.04 ./build.$GLOBAL_BASEARCH/image/boot/grub/theme/background.jpg
  sudo rm ./build.$GLOBAL_BASEARCH/image/boot/grub/theme/background.tiff 
  
  statusprint "Preparing font for grub bootloader.."
  install_required_package fonts-dejavu-core
  install_required_package grub-common
  FONTNAME="DejaVuSansMono.ttf"
  FONTSIZE=24
  FONTPATH="/usr/share/fonts/truetype/dejavu/$FONTNAME"
  statusprint "Generating grub font from $FONTNAME.."
  if [ ! -f "$FONTPATH" ]
  then
    statusprint "Couldn't find required font at $FONTPATH. Aborting.."
    exit 1;
  fi
  sudo grub-mkfont -s $FONTSIZE -o ./build.$GLOBAL_BASEARCH/image/boot/grub/font.pf2 "$FONTPATH"

  statusprint "Installing MBR grub.."
  chroot_exec build.$GLOBAL_BASEARCH/image "grub-install --target i386-pc --boot-directory=/boot --modules=\"part_msdos ext2\" --install-modules=\"ahci all_video ata biosdisk cat disk drivemap ehci gfxmenu gfxterm halt hdparm help linux nativedisk ohci pata jpeg probe reboot scsi uhci usb_keyboard usb vbe videoinfo videotest part_msdos part_gpt fat ext2 normal\" $LOOPDEV_IMG"

  statusprint "Installing EFI grub.."
  chroot_exec build.$GLOBAL_BASEARCH/image "grub-install --target x86_64-efi --efi-directory=/boot/efi --modules=\"part_gpt fat\" --install-modules=\"ahci all_video ata boot cat disk echo ehci efi_gop efi_uga font gfxmenu gfxterm_background gfxterm_menu gfxterm halt hdparm help linux linuxefi ls msdospart nativedisk ohci pata jpeg probe reboot scsi uhci usb_keyboard usb videoinfo videotest part_msdos part_gpt fat ext2 normal\" $LOOPDEV_IMG"


  statusprint "Unmounting image rootfs filesystem and removing loop devices.."
  sudo umount ./build.$GLOBAL_BASEARCH/image/boot/efi ./build.$GLOBAL_BASEARCH/image/boot ./build.$GLOBAL_BASEARCH/image
  sudo losetup -d $LOOPDEV_IMG

fi

exit 0;
