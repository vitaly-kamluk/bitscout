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

elif [ -n "${GLOBAL_VPNTYPE}" -a "${GLOBAL_VPNTYPE}" = "wireguard" ]; then
  statusprint "Installing Wireguard VPN.."
  chroot_exec build.$GLOBAL_BASEARCH/chroot 'DEBIAN_FRONTEND=noninteractive;
  aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c;
  apt-get --yes install wireguard-tools resolvconf' 

elif [ -n "${GLOBAL_VPNTYPE}" -a "${GLOBAL_VPNTYPE}" = "tor" ]; then
  statusprint "Installing TOR Hidden Service.."
  chroot_exec build.$GLOBAL_BASEARCH/chroot 'DEBIAN_FRONTEND=noninteractive;
  aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c;
  apt-get -y install tor'
else
  statusprint "No VPN will be installed: VPN type is set to \"$GLOBAL_VPNTYPE\""
fi

exit 0;
