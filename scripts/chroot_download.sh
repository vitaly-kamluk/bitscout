#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Checking requirements.."
if [ -z "$(which dpkg-query)" ]
then
 echo "dpkg is required to continue. Please install manually."
 exit 2
fi

if [ -d "./chroot" ]
then
  PRINTOPTIONS=n statusprint "Found existing chroot directory. Please choose what to do:\n 1. Remove existing chroot and re-download.\n 2. Do not re-download, skip this step.\n 3. Abort.\n You choice (1|2|3): "
  read choice

  case $choice in
    1)
     sudo rm -rf ./chroot/
     install_required_package debootstrap

      statusprint "Downloading $BASERELEASE:$BASEARCHITECTURE.."
      sudo debootstrap --arch=$BASEARCHITECTURE $BASERELEASE chroot
     ;;
    2)
      statusprint "Download operation skipped. Build continues.."
     ;; 
    *)
     statusprint "Operation aborted. Build stopped."
     ;;
  esac
fi

exit 0;
