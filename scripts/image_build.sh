#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Making sure package cache and other fs are detached.."
chroot_unmount_fs "./build.$GLOBAL_BASEARCH/chroot"

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
  install_required_package grub-common
  install_required_package grub-pc-bin
  install_required_package grub-efi-ia32-bin
  install_required_package grub-efi-amd64-bin
  install_required_package mtools
  install_required_package xorriso

  sudo grub-mkrescue --modules="part_gpt iso9660 linux ext2 fshelp ls boot jpeg video_bochs video_cirrus" --output=./$PROJECTNAME-$PROJECTRELEASE-$GLOBAL_BASEARCH.iso ./build.$GLOBAL_BASEARCH/image -- -as mkisofs -r -volid "${PROJECTNAME}-${GLOBAL_BUILDID}" -J -l -joliet-long -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -no-emul-boot

elif [ "$GLOBAL_TARGET" = "raw" ]; then

  if [ "$GLOBAL_PARTITION_TABLE" = "gpt" ]; then
    EFIPART_START=1
    EFIPART_SIZE=32 #MiB
  else
    EFIPART_SIZE=0
  fi


  statusprint "Preparing to build a raw disk image.."
  PERSISTSIZE_BYTES=$(normalize_size $GLOBAL_PERSISTSIZE)
  IMGSIZE=$( sudo du -B 512 -s ./build.$GLOBAL_BASEARCH/chroot/ 2>&1 | awk "{print 128*1048576 + \$1*512 + $PERSISTSIZE_BYTES + $EFIPART_SIZE*1048576 }" )
  IMGFILE=$PROJECTNAME-$PROJECTRELEASE-$GLOBAL_BASEARCH.$GLOBAL_TARGET

  statusprint "Target disk image size: $IMGSIZE"
  truncate -s $IMGSIZE "./$IMGFILE"
  IMGSIZEBYTES=$(stat -c %s "./$IMGFILE")
  PERSPARTSIZEBYTES=$( normalize_size $GLOBAL_PERSISTSIZE)

  if [ ! -f "./$IMGFILE" ]; then statusprint "Failed to create image file at $IMGFILE"; exit 1; fi; 

  statusprint "Building partition table ($GLOBAL_PARTITION_TABLE).."
  parted -s "./$IMGFILE" mklabel "$GLOBAL_PARTITION_TABLE"

  if [ "$GLOBAL_PARTITION_TABLE" = "gpt" ]; then
    statusprint "Adding EFI partition.."
    EFIPART_END=$[$EFIPART_START + $EFIPART_SIZE]
    parted -a optimal -s "./$IMGFILE" mkpart primary fat32 ${EFIPART_START}MiB ${EFIPART_END}MiB

    ROOTPART_START=$EFIPART_END
    ROOTPART_END=$[($IMGSIZEBYTES/1048576)-$ROOTPART_START-$PERSPARTSIZEBYTES/1048576]

    statusprint "Formatting EFI partition.."
    sudo mkfs -q -t fat32 -E offset=$[$EFIPART_START*1048576] -F -e remount-ro -L /boot/efi -U random "./$IMGFILE" ${EFIPART_SIZE}m
  elif [ "$GLOBAL_PARTITION_TABLE" = "msdos" ]; then
    ROOTPART_START=1
    ROOTPART_END=$[($IMGSIZEBYTES/1048576)-$ROOTPART_START-$PERSPARTSIZEBYTES/1048576]
  fi

  statusprint "Creating root partition.."
  parted -a optimal -s "./$IMGFILE" mkpart primary ext4 ${ROOTPART_START}MiB ${ROOTPART_END}MiB

  statusprint "Creating persistence partition.."
  PERSPART_START=$ROOTPART_END
  PERSPART_SIZE=$( awk '{print ($0/(1024*1024))}' <<< $PERSPARTSIZEBYTES ) #in MiB
  PERSPART_END=$[$PERSPART_START + $PERSPART_SIZE]
  parted -a optimal -s "./$IMGFILE" mkpart primary ext4 ${PERSPART_START}MiB ${PERSPART_END}MiB

  statusprint "Formatting persistence partition.."
  sudo mkfs -q -t ext4 -E offset=$[$PERSPART_START*1048576] -d ./resources/persistence -F -L /persistence -U random "./$IMGFILE" ${PERSPART_SIZE}m

  statusprint "Preparing loop devices.."

  statusprint "Preparing whole disk loop device.."
  LOOPDEV_IMG=$(sudo losetup -f)
  if [ ! -b $LOOPDEV_IMG ]; then statusprint "Couldn't find spare loop device for the image.."; exit 1; fi;
  sudo losetup -o 0 --sizelimit $IMGSIZEBYTES $LOOPDEV_IMG "./$IMGFILE"

  if [ "$GLOBAL_PARTITION_TABLE" = "gpt" ]; then
    statusprint "Preparing EFI partition loop device.."
    LOOPDEV_PART_EFI=$(sudo losetup -f)
    if [ ! -b $LOOPDEV_PART_EFI ]; then statusprint "Couldn't find spare loop device for the EFI partition.."; exit 1; fi;
    sudo losetup -o $[1048576*$EFIPART_START] --sizelimit $[$EFIPART_SIZE*1048576] $LOOPDEV_PART_EFI "./$IMGFILE"
  fi

  LOOPDEV_PART_ROOT=$(sudo losetup -f)
  if [ ! -b $LOOPDEV_PART_ROOT ]; then statusprint "Couldn't find spare loop device for the root partition.."; exit 1; fi;
  statusprint "Preparing root partition loop device.."
  sudo losetup -o $[$ROOTPART_START*1048576] --sizelimit $[($ROOTPART_END-$ROOTPART_START)*1048576] $LOOPDEV_PART_ROOT "./$IMGFILE"

  statusprint "Formatting and populating root partition via $LOOPDEV_PART_ROOT.."
  sudo mkfs -q -t ext4 -d ./build.$GLOBAL_BASEARCH/chroot/ -F -e remount-ro -L / -U random $LOOPDEV_PART_ROOT $[($ROOTPART_END-$ROOTPART_START)]m

  statusprint "Getting root partition UUID.."
  PART_ROOT_UUID=$(sudo blkid -o udev $LOOPDEV_PART_ROOT | awk -F= '/ID_FS_UUID=/{print $2}')

  LOOPDEV_PART_PERS=$(sudo losetup -f)
  if [ ! -b $LOOPDEV_PART_PERS ]; then statusprint "Couldn't find spare loop device for the persistence partition.."; exit 1; fi;
  statusprint "Preparing persistence partition loop device.."
  sudo losetup -o $[$PERSPART_START*1048576] --sizelimit $[($PERSPART_END-$PERSPART_START)*1048576] $LOOPDEV_PART_PERS "./$IMGFILE"

  statusprint "Getting persistence partition UUID.."
  PART_PERS_UUID=$(sudo blkid -o udev $LOOPDEV_PART_PERS | awk -F= '/ID_FS_UUID=/{print $2}')

  statusprint "Mounting target image rootfs.."
  sudo mount -t ext4 $LOOPDEV_PART_ROOT ./build.$GLOBAL_BASEARCH/image

  statusprint "Mounting persistence partition.."
  sudo mount -t ext4 $LOOPDEV_PART_PERS ./build.$GLOBAL_BASEARCH/image/persistence

  statusprint "Fixing ownership on persistence partition.."
  sudo chown root:root ./build.$GLOBAL_BASEARCH/image/persistence/host ./build.$GLOBAL_BASEARCH/image/persistence/container

  statusprint "Unmounting persistence filesystem.."
  sudo umount ./build.$GLOBAL_BASEARCH/image/persistence

  PROJDIR=$PWD
  statusprint "Adding and mounting devices to the mounted rootfs.."
  if [ "$GLOBAL_PARTITION_TABLE" = "gpt" ]; then
    pushd /dev >/dev/null
    tar -cpf- ${LOOPDEV_IMG##*/} ${LOOPDEV_PART_EFI##*/} ${LOOPDEV_PART_ROOT##*/} | sudo tar -xf- -C $PROJDIR/build.$GLOBAL_BASEARCH/image/dev
    popd >/dev/null
    sudo mount -t fat32 $LOOPDEV_PART_EFI ./build.$GLOBAL_BASEARCH/image/boot/efi
  elif [ "$GLOBAL_PARTITION_TABLE" = "msdos" ]; then
    pushd /dev >/dev/null
    tar -cpf- ${LOOPDEV_IMG##*/} ${LOOPDEV_PART_ROOT##*/} | sudo tar -xf- -C $PROJDIR/build.$GLOBAL_BASEARCH/image/dev
    popd >/dev/null
  fi

  statusprint "Adding new disk image loop device to the mounted rootfs.."
  if [ ! -b "./build.$GLOBAL_BASEARCH/image/dev/${LOOPDEV_IMG##*/}" ]; then 
    statusprint "Couldn't find loop device on the target rootfs."; 
    sudo umount ./build.$GLOBAL_BASEARCH/image 
    statusprint "Preparing boot partition loop device.."
    sudo losetup -d $LOOPDEV_PART_ROOT $LOOPDEV_PART_PERS $LOOPDEV_IMG $LOOPDEV_BOOT $LOOPDEV_EFI
    exit 1; 
  fi;

  if [ "$GLOBAL_PARTITION_TABLE" = "gpt" ]; then
    chroot_exec build.$GLOBAL_BASEARCH/image "grub-install --modules=\"part_gpt fat\" --install-modules=\"ahci all_video ata biosdisk cat disk drivemap ehci gfxmenu halt hdparm help linux nativedisk ohci pata png probe reboot scsi uhci usb_keyboard usb vbe videoinfo videotest part_gpt fat normal\" $LOOPDEV_IMG"
  elif [ "$GLOBAL_PARTITION_TABLE" = "msdos" ]; then
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
    chroot_exec build.$GLOBAL_BASEARCH/image "grub-install --modules=\"part_msdos ext2\" --install-modules=\"ahci all_video ata biosdisk cat disk drivemap ehci gfxmenu gfxterm halt hdparm help linux nativedisk ohci pata jpeg probe reboot scsi uhci usb_keyboard usb vbe videoinfo videotest part_msdos ext2 normal\" $LOOPDEV_IMG"
  fi

  statusprint "Unmounting image rootfs filesystem and removing loop devices.."
  sudo umount ./build.$GLOBAL_BASEARCH/image
  sudo losetup -d $LOOPDEV_PART_ROOT $LOOPDEV_PART_PERS $LOOPDEV_IMG $LOOPDEV_BOOT $LOOPDEV_EFI
fi

exit 0;
