#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

echo -en "This will recreate and download new chroot and should overwrite existing data.\nAre you sure you want to continue (Y/n)?: "
read choice

if [ ! -z "$choice" -a ! "$choice" == "y" -a ! "$choice" == "Y" ] 
then
  echo "Aborted."
  exit 1
else
  sudo rm -rf ./chroot/
fi

statusprint "Checking requirements.."

if [ -z "$(which dpkg-query)" ]
then
 echo "dpkg is required to continue. Please install manually."
 exit 2
fi


install_required_package debootstrap

statusprint "Downloading $BASERELEASE:$BASEARCHITECTURE.."
sudo debootstrap --arch=$BASEARCHITECTURE $BASERELEASE chroot


exit 0;
