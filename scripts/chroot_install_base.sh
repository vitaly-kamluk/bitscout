#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

./scripts/chroot_enter.sh

statusprint "Installing essential packages in chroot.."

runinchroot 'apt-get --yes update
DEBIAN_FRONTEND=noninteractive apt-get --yes -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" upgrade
DEBIAN_FRONTEND=noninteractive apt-get --yes install file hdparm iptables lshw usbutils parted lsof psmisc strace ltrace time systemd-sysv man-db dosfstools cron busybox-static rsync dmidecode bash-completion command-not-found ntfs-3g netcat socat uuid-runtime vim nano less pv dnsutils \
casper lupin-casper discover laptop-detect os-prober linux-image-generic \
lxc bindfs \
wicd-curses dialog tmux gawk
DEBIAN_FRONTEND=noninteractive apt-get --yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install grub-pc'

statusprint "Installing packages done."

statusprint "Removing older kernels in chroot.."
runinchroot 'LATEST_KERNEL=`ls -1 /boot/vmlinuz-*-generic | sort | tail -n1 | cut -d"-" -f2-`
count=$(ls -1 /boot/vmlinuz-*-generic | wc -l)
if [ $count -gt 1 ]; then
  dpkg -l "linux-*" | sed '"'"'/^ii/!d; /'"'"'"${LATEST_KERNEL}"'"'"'/d; s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d'"'"' | xargs sudo apt-get -y purge
fi'

statusprint "Removing unnecessary packages in chroot.."
runinchroot 'apt-get -y purge plymouth'


./scripts/chroot_leave.sh
exit 0;
