#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Resetting chroot/etc/hosts"
echo "127.0.0.1   localhost
127.0.1.1   $PROJECTNAME

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
#=========================" | sudo tee chroot/etc/hosts >/dev/null

statusprint "Updating chroot/etc/resolv.conf"
echo "nameserver 8.8.8.8" | sudo tee chroot/etc/resolv.conf >/dev/null

statusprint "Updating chroot/etc/apt/sources.lst"
echo "deb http://archive.ubuntu.com/ubuntu xenial main universe multiverse restricted
deb-src http://archive.ubuntu.com/ubuntu xenial main universe multiverse restricted

deb http://archive.ubuntu.com/ubuntu xenial-updates main universe multiverse restricted
deb-src http://archive.ubuntu.com/ubuntu xenial-updates main universe multiverse restricted

deb http://archive.ubuntu.com/ubuntu xenial-security main universe multiverse restricted
deb-src http://archive.ubuntu.com/ubuntu xenial-security main universe multiverse restricted
" | sudo tee chroot/etc/apt/sources.list >/dev/null

statusprint "Updating chroot/etc/hostname"
echo "$PROJECTNAME" | sudo tee chroot/etc/hostname >/dev/null

exit 0;
