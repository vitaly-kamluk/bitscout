#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions


statusprint "Leaving chroot.."
statusprint "Uninitializing chroot environment from within.."

chrootscreen_exec "rm /var/lib/dbus/machine-id 2>&-
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl
apt-get clean
umount -lf /dev/pts
umount -lf /dev
umount -lf /sys
umount -lf /proc"

typeinchroot "exit\n"

statusprint "Leaving chroot done."


