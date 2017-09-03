#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Setting up locale filter (localepurge).."
if [ -f "chroot/etc/locale.gen" ]
then 
  sudo sed -i 's,^# '$LANG' UTF-8$,'$LANG' UTF-8,' chroot/etc/locale.gen
else
  echo "$LANG UTF-8" | sudo tee chroot/etc/locale.gen >/dev/null
fi
statusprint "Generating locale.."
chroot_exec chroot 'locale-gen "'$LANG'"'

statusprint "Updating system and installing essential packages.."

if [ $GLOBAL_RELEASESIZE -eq 1 ]
then
  chroot_exec chroot 'export DEBIAN_FRONTEND=noninteractive
apt-get --yes update
apt-get --yes install -f localepurge aria2
aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c
apt-fast --yes -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" upgrade
apt-fast --yes install netcat socat casper lupin-casper discover laptop-detect os-prober lxc lxc1 bindfs dialog tmux gawk
apt-fast --yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install grub-pc ntpdate' 
else
  chroot_exec chroot 'export DEBIAN_FRONTEND=noninteractive
apt-get --yes update
apt-get --yes install -f localepurge aria2
aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c
apt-fast --yes -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" upgrade
apt-fast --yes install file hdparm iptables lshw usbutils parted lsof psmisc strace ltrace time systemd-sysv man-db dosfstools cron busybox-static rsync dmidecode bash-completion command-not-found ntfs-3g netcat socat uuid-runtime vim nano less pv casper lupin-casper discover laptop-detect os-prober lxc lxc1 bindfs wicd-curses dialog tmux gawk ntpdate nbd-server
apt-fast --yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install grub-pc qemu-kvm'
fi
statusprint "Finished installing packages."

statusprint "Upgrading kbd package." #kbd is updated separately, because of related GDM issue/bug.
chroot_exec chroot 'export DEBIAN_FRONTEND=noninteractive
apt-mark unhold kbd
cp /bin/kbd_mode.dist /bin/kbd_mode
aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c
apt-fast --yes -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" upgrade'

#statusprint "Removing older kernels in chroot.."
#chroot_exec chroot 'LATEST_KERNEL=`ls -1 /boot/vmlinuz-*-generic | sort | tail -n1 | cut -d"-" -f2-`
#count=$(ls -1 /boot/vmlinuz-*-generic | wc -l)
#if [ $count -gt 1 ]; then
#  dpkg -l "linux-*" | sed '"'"'/^ii/!d; /'"'"'"${LATEST_KERNEL}"'"'"'/d; s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d'"'"' | xargs sudo apt-get -y purge
#fi'

exit 0;
