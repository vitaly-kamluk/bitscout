#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Installing forensics packages in chroot.."
case $GLOBAL_RELEASESIZE in
 1)
   chroot_exec chroot 'DEBIAN_FRONTEND=noninteractive;
aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c;
apt-fast --yes install dd hexedit'
   ;;
 2)
   chroot_exec chroot 'DEBIAN_FRONTEND=noninteractive;
aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c;
apt-fast --yes install dcfldd sleuthkit plaso hexedit'
   ;;
 3)
   chroot_exec chroot 'export DEBIAN_FRONTEND=noninteractive;
aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c;
apt-fast --yes install dcfldd sleuthkit plaso forensics-all
apt-fast --yes install aircrack-ng bfbtester binwalk bruteforce-luks bzip2 cabextract chntpw clamav cmospwd crunch cryptmount dcfldd disktype dnsutils ethstatus ethtool exfat-fuse exfat-utils exif exiftags libimage-exiftool-perl exiv2 fatcat fdupes flasm foremost gdisk geoip-bin  hexedit hydra john lcrack less  mc mdadm medusa memstat mpack nasm neopi netcat nmap ntfs-3g ophcrack-cli outguess p7zip-full parted pcapfix pdfcrack poppler-utils pecomato pev pyrit rarcrack samdump2 sipcrack smb-nat snowdrop stegsnow sucrack sxiv tcpdump tcpflow tcpick tcpreplay tcpxtract telnet testdisk tshark uni2ascii unrar-free unzip wamerican wamerican-huge wamerican-insane wamerican-large wamerican-small wbrazilian wbritish wbritish-huge wbritish-insane wbritish-large wbritish-small wbulgarian wcanadian wcanadian-huge wcanadian-insane wcanadian-large wcanadian-small wcatalan weplab wfrench wgaelic wgerman-medical whois wifite wirish witalian wmanx wpolish wportuguese wspanish wswedish wukrainian'
   ;;
esac

exit 0;
