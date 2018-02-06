#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Disabling SSH server from automatic start on the host system.."
sudo touch chroot/etc/ssh/sshd_not_to_be_run

statusprint "Generating SSH-keys.."
if ! filelist_exists "config/ssh/"{${PROJECTSHORTNAME},${PROJECTSHORTNAME}.pub}
then
  mkdir -p config/ssh/ 2>&-
  install_required_package openssh-client
  ssh-keygen -b ${CRYPTOKEYSIZE} -N "" -f "config/ssh/${PROJECTSHORTNAME}"
else
  statusprint "Found existing SSH-keys. Using existing keys, new keys generation skipped."
fi

statusprint "Adding SSH-key to the authorized keys in chroot.."
sudo mkdir -p chroot/home/user/.ssh/
sudo cp "config/ssh/${PROJECTSHORTNAME}.pub" chroot/home/user/.ssh/authorized_keys

exit 0;
