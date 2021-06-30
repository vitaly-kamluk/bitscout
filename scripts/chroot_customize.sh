#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

#This file contains various customization templates, i.e. adding packages,
#installing python modules via pip, configuring services in chroot environment,
#adding reverse proxy over SSH.


. ./scripts/functions

statusprint "Adding custom packages and settings in chroot.."

#The following is executed as a script inside the chroot environment.
#Ignore the first line required for apt-fast (a faster alternative for apt)
chroot_exec build.$GLOBAL_BASEARCH/chroot \
'export DEBIAN_FRONTEND=noninteractive; aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c;

#apt-fast --yes install gdb chntpw libguestfs-tools
#apt-fast --yes install yara samba python-pip nbd-client xnbd-client nbd-server xnbd-server 
#pip install --upgrade pip
#pip install artifacts bencode libscca-python
#systemctl disable smbd
'


# ----------------------------------------------
# Proxy config
# This is useful to install missing package via
# a reverse-tunnel over SSH.
# Uncomment if you find it useful!
# Credits: Xavier Mertens <xavier@rootshell.be>
# ----------------------------------------------

#statusprint "Configuring localhost proxy.."
#echo -e "Acquire::http::Proxy \"http://127.0.0.1:3128/\";\n Acquire::http::Proxy \"http://127.0.0.1:3128/\";" | sudo tee "build.$GLOBAL_BASEARCH/chroot/etc/apt/apt.conf.d/proxy.conf" > /dev/null
#
#echo -e "export HTTP_PROXY="http://127.0.0.1:3128"\nexport HTTPS_PROXY=\"http://127.0.0.1:3128\"" | sudo tee "build.$GLOBAL_BASEARCH/chroot/etc/bash.bashrc" > /dev/null


exit 0;
