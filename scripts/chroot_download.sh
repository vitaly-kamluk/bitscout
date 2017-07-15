#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Checking base requirements.."
if [ -z "$(which dpkg-query)" ]
then
 echo "dpkg is required to continue. Please install manually."
 exit 2
fi

run_debootstrap_supervised()
{
  statusprint "Downloading $BASERELEASE:$BASEARCHITECTURE.."
  statusprint "Running debootstrap (stage 1).."
  sudo debootstrap --foreign --arch=$BASEARCHITECTURE $BASERELEASE chroot
  
  statusprint "Fixing keyboard-configuration GDM compatibility bug (divert kbd_mode).."
  TARGETDEB="./chroot$(grep "^kbd " chroot/debootstrap/debpaths | cut -d' ' -f2)"
  sudo ./scripts/deb_unpack.sh "$TARGETDEB"
  sudo cp -v "${TARGETDEB}.unp/data/bin/kbd_mode" ./chroot/bin/kbd_mode.dist
  sudo cp -v chroot/bin/true "${TARGETDEB}.unp/data/bin/kbd_mode"
  sudo ./scripts/deb_pack.sh "$TARGETDEB"
  
  statusprint "Running debootstrap (stage 2).."
  chroot_exec "/debootstrap/debootstrap --second-stage; apt-mark hold kbd;"

  #statusprint "Restoring original kbd_mode.."
  #sudo cp -v ./chroot/bin/kbd_mode.dist ./chroot/bin/kbd_mode
  
  statusprint "Deboostrap process completed."
}

if [ -d "./chroot" ]
then
  PRINTOPTIONS=n statusprint "Found existing chroot directory. Please choose what to do:\n 1. Remove existing chroot and re-download.\n 2. Do not re-download, skip this step.\n 3. Abort.\n You choice (1|2|3): "
  read choice

  case $choice in
    1)
      sudo rm -rf ./chroot/
      install_required_package debootstrap
      run_debootstrap_supervised
     ;;
    2)
      statusprint "Download operation skipped. Build continues.."
     ;; 
    *)
      statusprint "Operation aborted. Build stopped."
     ;;
  esac
else
  install_required_package debootstrap
  run_debootstrap_supervised
fi

exit 0;
