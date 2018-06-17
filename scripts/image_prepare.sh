#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Recreating directories for the new image.."
rm -rf ./build.$GLOBAL_BASEARCH/image/ 2>&-
mkdir -p ./build.$GLOBAL_BASEARCH/image/{casper,boot}

statusprint "Copying bootloader files.."
sudo cp ./build.$GLOBAL_BASEARCH/chroot/boot/vmlinuz-*-generic ./build.$GLOBAL_BASEARCH/image/casper/vmlinuz
sudo cp ./build.$GLOBAL_BASEARCH/chroot/boot/initrd.img-*-generic ./build.$GLOBAL_BASEARCH/image/casper/initrd.gz
sudo cp /boot/memtest86+.bin ./build.$GLOBAL_BASEARCH/image/casper/memtest

statusprint "Creating manifest.."
sudo chroot ./build.$GLOBAL_BASEARCH/chroot dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee ./build.$GLOBAL_BASEARCH/image/casper/filesystem.manifest >/dev/null
sudo cp -v ./build.$GLOBAL_BASEARCH/image/casper/filesystem.manifest ./build.$GLOBAL_BASEARCH/image/casper/filesystem.manifest-desktop
REMOVE='ubiquity ubiquity-frontend-gtk ubiquity-frontend-kde casper lupin-casper live-initramfs user-setup discover1 xresprobe os-prober libdebian-installer4'
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
echo "Ubuntu Remix 18.04 \"$PROJECTCAPNAME\"" > info  # Update version number to match your OS version
echo "A project by Vitaly Kamluk, Kaspersky Lab (www.kaspersky.com)." > release_notes_url
cd ../../../

statusprint "Copying boot configuration from resources.."
cp -r ./resources/boot/ ./build.$GLOBAL_BASEARCH/image/
sed -i "s/<PROJECTNAME>/${PROJECTNAME}/g; s/<PROJECTCAPNAME>/${PROJECTCAPNAME}/g; s/<PROJECTSHORTNAME>/${PROJECTSHORTNAME}/g; s/<CONTAINERUSERNAME>/${CONTAINERUSERNAME}/g; " ./build.$GLOBAL_BASEARCH/image/boot/grub/grub.cfg


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
grub-mkfont -s $FONTSIZE -o ./build.$GLOBAL_BASEARCH/image/boot/grub/font.pf2 "$FONTPATH"

exit 0;
