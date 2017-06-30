#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

install_required_package screen

statusprint "Entering chroot.."

statusprint "Binding /dev to chroot/dev"
sudo mount --bind /dev chroot/dev

statusprint "Binding /proc to chroot/proc"
sudo mount --bind /proc chroot/proc

statusprint "Binding /sys to chroot/sys"
sudo mount --bind /sys chroot/sys

statusprint "Binding /dev/pts to chroot/dev/pts"
sudo mount --bind /dev/pts chroot/dev/pts

#statusprint "Mounting tmpfs to chroot/tmp"
#sudo mount none -t tmpfs chroot/tmp

statusprint "Starting chroot in a screen session.."
if sudo screen -d -m -S ${PROJECTNAME}_chroot -U chroot chroot
then

 statusprint "Initializing chroot environment from within.."
 runinchroot "export HOME=/root
mkdir -p /var/lib/dbus 2>&-
dbus-uuidgen > /var/lib/dbus/machine-id 2>&-
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl 2>&-"

 statusprint "Entering chroot done."
else
 statusprint "Failed to start chrooted screen"
 exit 1
fi
