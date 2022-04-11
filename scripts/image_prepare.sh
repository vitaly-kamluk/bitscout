#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Recreating directories for the new image.."
rm -rf ./build.$GLOBAL_BASEARCH/image/ 2>&-
mkdir -p ./build.$GLOBAL_BASEARCH/image/

if [ "$GLOBAL_TARGET" = "iso" ]; then
  mkdir -p ./build.$GLOBAL_BASEARCH/image/{casper,boot}

  statusprint "Copying bootloader files.."
  sudo cp ./build.$GLOBAL_BASEARCH/chroot/boot/vmlinuz-*-generic ./build.$GLOBAL_BASEARCH/image/casper/vmlinuz &&
  sudo cp ./build.$GLOBAL_BASEARCH/chroot/boot/initrd.img-*-generic ./build.$GLOBAL_BASEARCH/image/casper/initrd.img &&
  install_required_package memtest86+ && 
  sudo cp /boot/memtest86+.bin ./build.$GLOBAL_BASEARCH/image/casper/memtest 

  statusprint "Creating manifest.."
  sudo chroot ./build.$GLOBAL_BASEARCH/chroot dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee ./build.$GLOBAL_BASEARCH/image/casper/filesystem.manifest >/dev/null
  sudo cp -v ./build.$GLOBAL_BASEARCH/image/casper/filesystem.manifest ./build.$GLOBAL_BASEARCH/image/casper/filesystem.manifest-desktop
  REMOVE='ubiquity ubiquity-frontend-gtk ubiquity-frontend-kde casper live-initramfs user-setup discover1 xresprobe os-prober libdebian-installer4'
  for i in $REMOVE 
  do
    sudo sed -i "/${i}/d" ./build.$GLOBAL_BASEARCH/image/casper/filesystem.manifest-desktop
  done


  statusprint "Setting disk properties.."
  ( echo "#define DISKNAME  Ubuntu Remix
  #define TYPE  binary
  #define TYPEbinary  1
  #define ARCH  $GLOBAL_BASEARCH";
  if [ "$GLOBAL_BASEARCH" == "i386" ]
  then
   echo "#define ARCHi386  1"
  else
   echo "#define ARCHi386 0"
  fi

  echo "#define DISKNUM  1
  #define DISKNUM1  1
  #define TOTALNUM  0
  #define TOTALNUM0  1" ) > ./build.$GLOBAL_BASEARCH/image/README.diskdefines

  statusprint "Making the image recognized as Ubuntu disk.."
  touch ./build.$GLOBAL_BASEARCH/image/ubuntu
  mkdir ./build.$GLOBAL_BASEARCH/image/.disk
  cd ./build.$GLOBAL_BASEARCH/image/.disk
  echo "live" > cd_type
  echo "Ubuntu Remix 22.04 \"$PROJECTCAPNAME\"" > info  # Update version number to match your OS version
  echo "A project by Vitaly Kamluk, Kaspersky Lab (www.kaspersky.com)." > release_notes_url
  cd ../../../

  statusprint "Copying boot configuration from resources.."
  cp -r ./resources/boot/ ./build.$GLOBAL_BASEARCH/image/
  sudo rm ./build.$GLOBAL_BASEARCH/image/boot/grub/grub.cfg.doublesword
  sudo mv ./build.$GLOBAL_BASEARCH/image/boot/grub/grub.cfg.casper ./build.$GLOBAL_BASEARCH/image/boot/grub/grub.cfg
  sed -i "s/<PROJECTNAME>/${PROJECTNAME}/g; s/<PROJECTCAPNAME>/${PROJECTCAPNAME}/g; s/<PROJECTSHORTNAME>/${PROJECTSHORTNAME}/g; s/<CONTAINERUSERNAME>/${CONTAINERUSERNAME}/g; s/<PROJECTRELEASE>/${PROJECTRELEASE}/g;" ./build.$GLOBAL_BASEARCH/image/boot/grub/grub.cfg

  statusprint "Altering boot splash image.."
  install_required_package imagemagick
  convert -quiet ./build.$GLOBAL_BASEARCH/image/boot/grub/theme/background.jpg +repage ./build.$GLOBAL_BASEARCH/image/boot/grub/theme/background.tiff
  convert ./build.$GLOBAL_BASEARCH/image/boot/grub/theme/background.tiff \( -clone 0 -fill srgb\(255,255,255\) -colorize 100% -modulate 100,100,100 \) \( -clone 0 -blur 0x1 -fuzz 10% -fill none -draw "matte 580,630 floodfill" -channel rgba -fill black +opaque none -fill white -opaque none -blur 0x8 -auto-level -evaluate multiply 1 \) -compose over -composite -pointsize 22 -font /usr/share/fonts/truetype/ubuntu/Ubuntu-B.ttf -fill rgba\(255,255,255,0.8\) -annotate +750+580 22.04 ./build.$GLOBAL_BASEARCH/image/boot/grub/theme/background.jpg
  rm ./build.$GLOBAL_BASEARCH/image/boot/grub/theme/background.tiff

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
  grub-mkfont -s $FONTSIZE -o ./build.$GLOBAL_BASEARCH/image/boot/grub/font.pf2 "$FONTPATH"
else
  statusprint "Installing grub package.."
  chroot_exec build.$GLOBAL_BASEARCH/chroot "export DEBIAN_FRONTEND=noninteractive; apt-fast --yes install grub-efi"
  statusprint "Preparing persistence mount directories.."
  sudo mkdir -p ./build.$GLOBAL_BASEARCH/chroot/persistence/{host,container}/overlay/{work,upper}
  sudo mkdir -p ./build.$GLOBAL_BASEARCH/chroot/rofs

  statusprint "Copying boot configuration from resources.."
  sudo cp -rv ./resources/boot/* ./build.$GLOBAL_BASEARCH/chroot/boot/
  sudo rm ./build.$GLOBAL_BASEARCH/chroot/boot/grub/grub.cfg.casper
  sudo mv ./build.$GLOBAL_BASEARCH/chroot/boot/grub/grub.cfg.doublesword ./build.$GLOBAL_BASEARCH/chroot/boot/grub/grub.cfg
  sudo sed -i "s/<PROJECTNAME>/${PROJECTNAME}/g; s/<PROJECTCAPNAME>/${PROJECTCAPNAME}/g; s/<PROJECTSHORTNAME>/${PROJECTSHORTNAME}/g; s/<CONTAINERUSERNAME>/${CONTAINERUSERNAME}/g; s/<PROJECTRELEASE>/${PROJECTRELEASE}/g;" ./build.$GLOBAL_BASEARCH/chroot/boot/grub/grub.cfg

  statusprint "Altering boot splash image.."
  install_required_package imagemagick
  sudo convert -quiet ./build.$GLOBAL_BASEARCH/chroot/boot/grub/theme/background.jpg +repage ./build.$GLOBAL_BASEARCH/chroot/boot/grub/theme/background.tiff
  sudo convert ./build.$GLOBAL_BASEARCH/chroot/boot/grub/theme/background.tiff \( -clone 0 -fill srgb\(255,255,255\) -colorize 100% -modulate 100,100,100 \) \( -clone 0 -blur 0x1 -fuzz 10% -fill none -draw "matte 580,630 floodfill" -channel rgba -fill black +opaque none -fill white -opaque none -blur 0x8 -auto-level -evaluate multiply 1 \) -compose over -composite -pointsize 22 -font /usr/share/fonts/truetype/ubuntu/Ubuntu-B.ttf -fill rgba\(255,255,255,0.8\) -annotate +750+580 22.04 ./build.$GLOBAL_BASEARCH/chroot/boot/grub/theme/background.jpg
  sudo rm ./build.$GLOBAL_BASEARCH/chroot/boot/grub/theme/background.tiff 
  
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
  sudo grub-mkfont -s $FONTSIZE -o ./build.$GLOBAL_BASEARCH/chroot/boot/grub/font.pf2 "$FONTPATH"
  statusprint "Adding overlay module.."
  echo "overlay" | sudo tee -a  ./build.$GLOBAL_BASEARCH/chroot/etc/initramfs-tools/modules
  chroot_exec ./build.$GLOBAL_BASEARCH/chroot 'update-initramfs -u'
fi

exit 0;
