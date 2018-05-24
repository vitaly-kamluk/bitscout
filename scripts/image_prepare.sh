#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Recreating directories for the new image.."
rm -rf image/ 2>&-
mkdir -p image/{casper,boot}

statusprint "Copying bootloader files.."
sudo cp chroot/boot/vmlinuz-*-generic image/casper/vmlinuz
sudo cp chroot/boot/initrd.img-*-generic image/casper/initrd.gz
sudo cp /boot/memtest86+.bin image/casper/memtest

statusprint "Creating manifest.."
sudo chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee image/casper/filesystem.manifest >/dev/null
sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop
REMOVE='ubiquity ubiquity-frontend-gtk ubiquity-frontend-kde casper lupin-casper live-initramfs user-setup discover1 xresprobe os-prober libdebian-installer4'
for i in $REMOVE 
do
  sudo sed -i "/${i}/d" image/casper/filesystem.manifest-desktop
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
#define TOTALNUM0  1" ) > image/README.diskdefines

statusprint "Making the image recognized as Ubuntu disk.."
touch image/ubuntu
mkdir image/.disk
cd image/.disk
echo "live" > cd_type
echo "Ubuntu Remix 18.04 \"$PROJECTCAPNAME\"" > info  # Update version number to match your OS version
echo "A project by Vitaly Kamluk, Kaspersky Lab (www.kaspersky.com)." > release_notes_url
cd ../../

statusprint "Copying boot configuration from resources.."
cp -r ./resources/boot/ ./image/
sed -i "s/<PROJECTNAME>/${PROJECTNAME}/g; s/<PROJECTCAPNAME>/${PROJECTCAPNAME}/g; s/<PROJECTSHORTNAME>/${PROJECTSHORTNAME}/g; s/<CONTAINERUSERNAME>/${CONTAINERUSERNAME}/g; " ./image/boot/grub/grub.cfg


statusprint "Preparing font for grub bootloader.."
install_required_package fonts-dejavu-core
install_required_package grub-common
FONTNAME="DejaVuSansMono.ttf"
FONTSIZE=18
FONTPATH="/usr/share/fonts/truetype/dejavu/$FONTNAME"
statusprint "Generating grub font from $FONTNAME.."
if [ ! -f "$FONTPATH" ]
then
  statusprint "Couldn't find required font at $FONTPATH. Aborting.."
  exit 1;
fi
grub-mkfont -s $FONTSIZE -o ./image/boot/grub/font.pf2 "$FONTPATH"

exit 0;
