#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

install_required_package screen
statusprint "Entering ./build.$GLOBAL_BASEARCH/chroot.."

if screen -ls "${PROJECTNAME}_${GLOBAL_BASEARCH}_chroot" >/dev/null; 
then 
  statusprint "Chroot session is already running."
  exit 1
fi

statusprint "Mounting build.$GLOBAL_BASEARCH/chroot/dev"
if [ ! -d "./build.$GLOBAL_BASEARCH/chroot/dev" ]
then
  sudo mkdir -p ./build.$GLOBAL_BASEARCH/chroot/dev
  cd ./build.$GLOBAL_BASEARCH/chroot/dev
  sudo MAKEDEV std
  cd ../../../
fi
sudo mount -t devpts devpts build.$GLOBAL_BASEARCH/chroot/dev/pts

statusprint "Mounting build.$GLOBAL_BASEARCH/chroot/proc"
sudo mount -t proc proc build.$GLOBAL_BASEARCH/chroot/proc

statusprint "Mounting build.$GLOBAL_BASEARCH/chroot/sys"
sudo mount -t sysfs sysfs build.$GLOBAL_BASEARCH/chroot/sys

statusprint "Starting build.$GLOBAL_BASEARCH/chroot in a screen session.."
sudo chmod o+rwX ./build.$GLOBAL_BASEARCH/chroot/tmp
if sudo screen -d -m -S "${PROJECTNAME}_${GLOBAL_BASEARCH}_chroot" -U build.$GLOBAL_BASEARCH/chroot build.$GLOBAL_BASEARCH/chroot
then

 statusprint "Initializing chroot environment from within.."
 chrootscreen_exec "export HOME=/root
mkdir -p /var/lib/dbus 2>&-
dbus-uuidgen > /var/lib/dbus/machine-id 2>&-
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl 2>&-"

 statusprint "Entering .build.$GLOBAL_BASEARCH/chroot done."
else
 statusprint "Failed to start chrooted screen"
 exit 1
fi
