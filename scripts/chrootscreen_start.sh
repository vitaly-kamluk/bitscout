#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

install_required_package screen
statusprint "Entering chroot.."

if screen -ls "${PROJECTNAME}_chroot" >/dev/null; 
then 
  statusprint "Chroot session is already running."
  exit 1
fi

statusprint "Mounting chroot/dev"
if [ ! -d "chroot/dev" ]
then
  sudo mkdir -p chroot/dev
  cd chroot/dev
  sudo MAKEDEV std
  cd ../../
fi
sudo mount -t devpts devpts chroot/dev/pts

statusprint "Mounting chroot/proc"
sudo mount -t proc proc chroot/proc

statusprint "Mounting chroot/sys"
sudo mount -t sysfs sysfs chroot/sys

statusprint "Starting chroot in a screen session.."
sudo chmod o+rwX chroot/tmp
if sudo screen -d -m -S "${PROJECTNAME}_chroot" -U chroot chroot
then

 statusprint "Initializing chroot environment from within.."
 chrootscreen_exec "export HOME=/root
mkdir -p /var/lib/dbus 2>&-
dbus-uuidgen > /var/lib/dbus/machine-id 2>&-
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl 2>&-"

 statusprint "Entering chroot done."
else
 statusprint "Failed to start chrooted screen"
 exit 1
fi
