#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Installing forensics packages in chroot.."
case $GLOBAL_RELEASESIZE in
 1)
   chroot_exec build.$GLOBAL_BASEARCH/chroot 'DEBIAN_FRONTEND=noninteractive;
aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c;
apt-fast --yes install coreutils hexedit' || exit 1
   ;;
 2)
   chroot_exec build.$GLOBAL_BASEARCH/chroot 'DEBIAN_FRONTEND=noninteractive;
aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c;
apt-fast --yes install coreutils dcfldd gddrescue sleuthkit hexedit indent chntpw tcpdump' || exit 1
   ;;
 3)
   chroot_exec build.$GLOBAL_BASEARCH/chroot 'export DEBIAN_FRONTEND=noninteractive;
aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c;
apt-fast --yes install coreutils dcfldd gddrescue sleuthkit forensics-all indent chntpw tcpdump
apt-fast --yes install bfbtester binwalk bruteforce-luks bzip2 cabextract chntpw clamav cmospwd crunch cryptmount dcfldd disktype dnsutils ethstatus ethtool exfat-fuse exfat-utils exif exiftags libimage-exiftool-perl exiv2 fatcat fdupes flasm foremost gdisk geoip-bin  hexedit john less mc mdadm medusa memstat mpack nasm neopi netcat nmap ntfs-3g ophcrack-cli outguess p7zip-full parted pcapfix pdfcrack poppler-utils pecomato pev rarcrack samdump2 smb-nat snowdrop stegsnow sucrack sxiv tcpdump tcpflow tcpick tcpreplay tcpxtract telnet testdisk uni2ascii unrar-free unzip whois gdb libguestfs-tools
systemctl disable clamav-freshclam' || exit 1;
   statusprint "Disabling network new services in chroot.."
   chroot_exec build.$GLOBAL_BASEARCH/chroot 'systemctl disable clamav-freshclam && systemctl stop clamav-freshclam &&
   systemctl disable postfix && systemctl stop postfix';
   ;;
esac

exit 0;
