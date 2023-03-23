#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Making sure package cache and other fs are detached.."
chroot_unmount_fs "./build.$GLOBAL_BASEARCH/chroot"
sudo umount -l "./build.$GLOBAL_BASEARCH/image/persistence" 2>/dev/null
sudo umount -l "./build.$GLOBAL_BASEARCH/image" 2>/dev/null

if [ "$GLOBAL_TARGET" = "iso" ]; then
  GLOBAL_PARTITION_TABLE="hybrid"
fi

install_required_package grub-common
case "$GLOBAL_PARTITION_TABLE" in
  "msdos") install_required_package grub-pc-bin;;

  "gpt") install_required_package grub-efi-ia32-bin;
         install_required_package grub-efi-amd64-bin;;

  "hybrid")
         install_required_package grub-pc-bin;
         install_required_package grub-efi-ia32-bin;
         install_required_package grub-efi-amd64-bin;;
   *) statusprint "Unsupported partition table type: $GLOBAL_PARTITION_TABLE"
     exit 1;;
esac

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

elif [ "$GLOBAL_TARGET" != "iso" ]; then
  statusprint "Preparing to build a raw disk image.."
  install_required_package gdisk

  case "${GLOBAL_PARTITION_TABLE}" in
    "msdos")
      ROOTPART_START_MB=1
     ;;
    "gpt")
      EFIPART_START_MB=1
      EFIPART_SIZE_MB=128
      ROOTPART_START_MB=$[$EFIPART_START_MB + $EFIPART_SIZE_MB]
     ;;
    "hybrid")
      BIOSGRUB_START_MB=1
      BIOSGRUB_SIZE_MB=1
      EFIPART_START_MB=$[$BIOSGRUB_START_MB + $BIOSGRUB_SIZE_MB]
      EFIPART_SIZE_MB=128
      ROOTPART_START_MB=$[$EFIPART_START_MB + $EFIPART_SIZE_MB]
     ;;
  esac

  ROOTPART_SIZE_MB=$( sudo tar c ./build.$GLOBAL_BASEARCH/chroot/ 2>&1 | wc -c | awk '{ print(int($1/(1024*1024) + 256))}' ) # more accurate estimation

  PERSPART_START_MB=$[ $ROOTPART_START_MB + $ROOTPART_SIZE_MB ]
  PERSPART_SIZE_B=$( normalize_size $GLOBAL_PERSISTSIZE )
  PERSPART_SIZE_MB=$( awk '{print $0/(1024*1024)}' <<<$PERSPART_SIZE_B )

  IMG_SIZE_MB=$[$PERSPART_START_MB+$PERSPART_SIZE_MB+1]
  IMG_SIZE_B=$[$IMG_SIZE_MB*1024*1024]
  IMGFILE=$PROJECTNAME-$PROJECTRELEASE-$GLOBAL_BASEARCH.raw

  statusprint "Target disk image size: $IMG_SIZE_B bytes"
  [ -f "./$IMGFILE" ] && rm -f "./$IMGFILE" 2>&1
  truncate -s $IMG_SIZE_B "./$IMGFILE"
  if [ ! -f "./$IMGFILE" ]; then statusprint "Failed to create image file at $IMGFILE"; exit 1; fi; 


  case "${GLOBAL_PARTITION_TABLE}" in
    "msdos")
      statusprint "Building MSDOS partition table.."
      parted -s "./$IMGFILE" mklabel msdos
      parted -a optimal -s "./$IMGFILE" mkpart primary ext4 ${ROOTPART_START_MB}MiB $[${ROOTPART_START_MB}+${ROOTPART_SIZE_MB}]MiB
      parted -a optimal -s "./$IMGFILE" mkpart primary ext4 ${PERSPART_START_MB}MiB $[${PERSPART_START_MB}+${PERSPART_SIZE_MB}]MiB
     ;;
    "gpt")
      statusprint "Building GPT partition table.."
      #sgdisk -g "./$IMGFILE"
      sgdisk -n 1::+${EFIPART_SIZE_MB}M -t 1:EF00 -n 2::+${ROOTPART_SIZE_MB}M -t 2:8300 -n 3::+${PERSPART_SIZE_MB}M -t 3:8300 "./$IMGFILE"
     ;;
    "hybrid")
      statusprint "Building hybrid MSDOS+GPT partition table.."
      sgdisk -h "./$IMGFILE"
      sgdisk -n 1::+${BIOSGRUB_SIZE_MB}M -t 1:EF02 -n 2::+${EFIPART_SIZE_MB}M -t 2:EF00 -n 3::+${ROOTPART_SIZE_MB}M -t 3:8300 -n 4::+${PERSPART_SIZE_MB}M -t 4:8300 "./$IMGFILE"
     ;;
  esac


  statusprint "Preparing loop devices.."
  LOOPDEV_IMG=$(sudo losetup -f)
  if [ ! -b ${LOOPDEV_IMG} ]; then statusprint "Couldn't find spare loop device for the image.."; exit 1; fi;
  sudo losetup --partscan ${LOOPDEV_IMG} "./$IMGFILE"

  case "${GLOBAL_PARTITION_TABLE}" in
    "msdos")
      LOOPDEV_PART_ROOT=${LOOPDEV_IMG}p1
      LOOPDEV_PART_PERS=${LOOPDEV_IMG}p2
     ;;
    "gpt")
      LOOPDEV_PART_EFI=${LOOPDEV_IMG}p1
      LOOPDEV_PART_ROOT=${LOOPDEV_IMG}p2
      LOOPDEV_PART_PERS=${LOOPDEV_IMG}p3
     ;;
    "hybrid")
      LOOPDEV_PART_BIOS_GRUB=${LOOPDEV_IMG}p1
      LOOPDEV_PART_EFI=${LOOPDEV_IMG}p2
      LOOPDEV_PART_ROOT=${LOOPDEV_IMG}p3
      LOOPDEV_PART_PERS=${LOOPDEV_IMG}p4
     ;;
  esac


  if [ -n "$LOOPDEV_PART_EFI" ]; then
    statusprint "Formatting EFI partition.."
    sudo mkfs.fat -F32 -n EFI $LOOPDEV_PART_EFI
  fi

  statusprint "Formatting and populating root partition.."
  sudo mkfs -q -t ext4 -d ./build.${GLOBAL_BASEARCH}/chroot -F -e remount-ro -L / -U random $LOOPDEV_PART_ROOT

  statusprint "Formatting and populating persistence partition.."
  if [ -d ./resources/persistence ]; then
    sudo mkfs -q -t ext4 -d ./resources/persistence -F -L /persistence -U random $LOOPDEV_PART_PERS
  else
    sudo mkfs -q -t ext4 -F -L persistence -U random $LOOPDEV_PART_PERS
  fi

  statusprint "Getting root partition UUID.."
  PART_ROOT_UUID=$(sudo blkid -o udev ${LOOPDEV_PART_ROOT} | awk -F= '/ID_FS_UUID=/{print $2}')

  statusprint "Getting persistence partition UUID.."
  PART_PERS_UUID=$(sudo blkid -o udev ${LOOPDEV_PART_PERS} | awk -F= '/ID_FS_UUID=/{print $2}')

  statusprint "Mounting target image rootfs.."
  sudo mount -t ext4 ${LOOPDEV_PART_ROOT} ./build.${GLOBAL_BASEARCH}/image

  if [ -n "$LOOPDEV_PART_EFI" ]; then
    statusprint "Mounting EFI partition.."
    [ ! -d "./build.${GLOBAL_BASEARCH}/image/boot/efi" ] && sudo mkdir -p ./build.${GLOBAL_BASEARCH}/image/boot/efi
    sudo mount -t vfat ${LOOPDEV_PART_EFI} ./build.${GLOBAL_BASEARCH}/image/boot/efi
  fi

  statusprint "Mounting persistence partition.."
  sudo mount -t ext4 ${LOOPDEV_PART_PERS} ./build.${GLOBAL_BASEARCH}/image/persistence

  statusprint "Unmounting persistence filesystem.."
  sudo umount -l ./build.${GLOBAL_BASEARCH}/image/persistence

  PROJDIR=$PWD
  statusprint "Adding target loop devices to the mounted rootfs.."
  pushd /dev >/dev/null
  tar -cpf- ${LOOPDEV_IMG##*/} ${LOOPDEV_PART_EFI##*/} ${LOOPDEV_PART_ROOT##*/} ${LOOPDEV_PART_PERS##*/} | sudo tar -xf- -C $PROJDIR/build.$GLOBAL_BASEARCH/image/dev
  popd >/dev/null

  if [ ! -b "./build.$GLOBAL_BASEARCH/image/dev/${LOOPDEV_IMG##*/}" ]; then 
    statusprint "Couldn't find loop device on the target rootfs."; 
    sudo umount ./build.$GLOBAL_BASEARCH/image/boot/efi ./build.$GLOBAL_BASEARCH/image/boot ./build.$GLOBAL_BASEARCH/image 2>/dev/null
    sudo losetup -d $LOOPDEV_IMG
    exit 1; 
  fi;

  statusprint "Updating partitions UUID for grub.."
  sudo sed -i "s/root=UUID=[0-9a-zA-Z-]*/root=UUID=${PART_ROOT_UUID}/g; s/persist=UUID=[0-9a-zA-Z-]*/persist=UUID=${PART_PERS_UUID}/g;" ./build.$GLOBAL_BASEARCH/image/boot/grub/grub.cfg

  if [ "$GLOBAL_PARTITION_TABLE" = "msdos" -o "$GLOBAL_PARTITION_TABLE" = "hybrid" ]; then
    statusprint "Installing MBR grub.."
    chroot_exec build.$GLOBAL_BASEARCH/image "grub-install --target i386-pc --boot-directory=/boot --modules=\"part_msdos ext2 vbe\" --install-modules=\"ahci all_video ata biosdisk cat disk drivemap ehci gfxmenu gfxterm halt hdparm help linux nativedisk ohci pata jpeg probe reboot scsi uhci usb_keyboard usb vbe videoinfo videotest part_msdos part_gpt fat ext2 normal\" $LOOPDEV_IMG"
  fi;

  if [ "$GLOBAL_PARTITION_TABLE" = "gpt" -o "$GLOBAL_PARTITION_TABLE" = "hybrid" ]; then
    statusprint "Installing EFI grub.."
    chroot_exec build.$GLOBAL_BASEARCH/image "grub-install --target x86_64-efi --efi-directory=/boot/efi --modules=\"part_gpt fat\" --install-modules=\"ahci all_video ata boot cat disk echo ehci efi_gop efi_uga font gfxmenu gfxterm_background gfxterm_menu gfxterm halt hdparm help linux linuxefi ls msdospart nativedisk ohci pata jpeg probe reboot scsi uhci usb_keyboard usb videoinfo videotest part_msdos part_gpt fat ext2 normal\" $LOOPDEV_IMG"
  fi

  statusprint "Unmounting image rootfs filesystem and removing loop devices.."
  sudo umount ./build.$GLOBAL_BASEARCH/image/boot/efi ./build.$GLOBAL_BASEARCH/image 2>/dev/null
  sudo losetup -d $LOOPDEV_IMG

  if [ -n "$GLOBAL_TARGET" -a "$GLOBAL_TARGET" != "raw" ]; then
    statusprint "Converting image to $GLOBAL_TARGET format.."
    install_required_package qemu-utils
    case ${GLOBAL_TARGET} in
      qcow2)
          qemu-img convert -f raw -O qcow2 $IMGFILE $PROJECTNAME-$PROJECTRELEASE-$GLOBAL_BASEARCH.qcow2
          rm "$IMGFILE"
        ;;
      vmdk) 
          qemu-img convert -f raw -O vmdk $IMGFILE $PROJECTNAME-$PROJECTRELEASE-$GLOBAL_BASEARCH.vmdk
          rm "$IMGFILE"
        ;;
    esac
  fi

fi

exit 0;
