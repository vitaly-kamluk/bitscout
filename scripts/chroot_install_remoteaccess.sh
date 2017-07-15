#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Installing remote access packages in chroot.."
chroot_exec 'DEBIAN_FRONTEND=noninteractive apt-get --yes install openvpn openssh-server irssi'

exit 0;
