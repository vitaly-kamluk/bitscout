#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Installing remote access packages in chroot.."
chroot_exec build.$GLOBAL_BASEARCH/chroot 'DEBIAN_FRONTEND=noninteractive;
aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c;
apt-get --yes install openvpn openssh-server irssi'

exit 0;
