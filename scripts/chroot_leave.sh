#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions


statusprint "Leaving chroot.."
statusprint "Uninitializing chroot environment from within.."

runinchroot "rm /var/lib/dbus/machine-id 2>&-
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl
apt-get clean
umount -lf /sys
umount -lf /dev
umount -lf /proc"

typeinchroot "exit\n"

statusprint "Leaving chroot done."


