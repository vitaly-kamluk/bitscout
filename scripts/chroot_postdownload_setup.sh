#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Resetting ./build.$GLOBAL_BASEARCH/chroot/etc/hosts"
echo "127.0.0.1   localhost
127.0.1.1   $PROJECTNAME

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
#=========================" | sudo tee ./build.$GLOBAL_BASEARCH/chroot/etc/hosts >/dev/null

statusprint "Updating ./build.$GLOBAL_BASEARCH/chroot/etc/resolv.conf"
echo "nameserver 8.8.8.8" | sudo tee ./build.$GLOBAL_BASEARCH/chroot/etc/resolv.conf >/dev/null

statusprint "Updating ./build.$GLOBAL_BASEARCH/chroot/etc/hostname"
echo "$PROJECTNAME" | sudo tee ./build.$GLOBAL_BASEARCH/chroot/etc/hostname >/dev/null

statusprint "Resetting root account inside new rootfs.."
chroot_exec "./build.$GLOBAL_BASEARCH/chroot" "passwd -d root"

exit 0;
