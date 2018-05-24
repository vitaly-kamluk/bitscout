#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Installing user choice pacakges in chroot.."
chroot_exec chroot 'export DEBIAN_FRONTEND=noninteractive;
aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c;
# uncomment and change the line below to add gdb or other packages of your choice
# apt-fast --yes install gdb
# apt-fast --yes install samba gdb python-pip gdb nbd-client xnbd-client nbd-server xnbd-server 
# pip install --upgrade pip
# pip install artifacts bencode libscca-python
# systemctl disable smbd'

exit 0;
