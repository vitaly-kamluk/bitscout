#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Installing remote access packages in chroot.."
chroot_exec build.$GLOBAL_BASEARCH/chroot 'DEBIAN_FRONTEND=noninteractive;
aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c;
apt-get --yes install openssh-server irssi'

if [ -n "${GLOBAL_VPNTYPE}" -a "${GLOBAL_VPNTYPE}" = "openvpn" ]
then
  statusprint "Installing OpenVPN.."
  chroot_exec build.$GLOBAL_BASEARCH/chroot 'DEBIAN_FRONTEND=noninteractive;
  aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c;
  apt-get --yes install openvpn'
else
  statusprint "OpenVPN will not be installed: VPN type is set to \"$GLOBAL_VPNTYPE\""
fi

exit 0;
