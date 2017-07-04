#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

./scripts/chroot_enter.sh

statusprint "Installing remote access packages in chroot.."
runinchroot 'DEBIAN_FRONTEND=noninteractive apt-get --yes install openvpn openssh-server irssi'

./scripts/chroot_leave.sh
exit 0;
