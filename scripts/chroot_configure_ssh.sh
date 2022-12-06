#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Disabling SSH server from automatic start on the host system.."
sudo touch ./build.$GLOBAL_BASEARCH/chroot/etc/ssh/sshd_not_to_be_run

statusprint "Generating SSH-keys.."
if ! filelist_exists "config/ssh/"{${PROJECTSHORTNAME},${PROJECTSHORTNAME}.pub}
then
  mkdir -p config/ssh/ 2>&-
  install_required_package openssh-client
  ssh-keygen -b ${CRYPTOKEYSIZE} -N "" -f "config/ssh/${PROJECTSHORTNAME}"
else
  statusprint "Found existing SSH-keys. Using existing keys, new keys generation skipped."
fi

statusprint "Adding SSH-key to the authorized keys in chroot for normal user.."
sudo mkdir -p ./build.$GLOBAL_BASEARCH/chroot/home/user/.ssh/
sudo cp "config/ssh/${PROJECTSHORTNAME}.pub" ./build.$GLOBAL_BASEARCH/chroot/home/user/.ssh/authorized_keys

statusprint "Adding SSH-key to the authorized keys in chroot for root.."
sudo mkdir -p ./build.$GLOBAL_BASEARCH/chroot/root/.ssh/
sudo cp "config/ssh/${PROJECTSHORTNAME}.pub" ./build.$GLOBAL_BASEARCH/chroot/root/.ssh/authorized_keys

statusprint "Disabling password authentication for SSH.."
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' ./build.$GLOBAL_BASEARCH/chroot/etc/ssh/sshd_config

statusprint "Uncommenting port option for SSH.."
sudo sed -i 's/^#Port /Port /g' ./build.$GLOBAL_BASEARCH/chroot/etc/ssh/sshd_config

statusprint "Setting custom SSH banner.."
mkdir -p "./build.$GLOBAL_BASEARCH/chroot/etc/ssh/sshd_config.d" 2>/dev/null
if ! grep -q "^VersionAddendum" "./build.$GLOBAL_BASEARCH/chroot/etc/ssh/sshd_config.d/banner.conf" 2>/dev/null; then
  echo "VersionAddendum ${PROJECTCAPNAME} ${PROJECTRELEASE}" | sudo tee -a "./build.$GLOBAL_BASEARCH/chroot/etc/ssh/sshd_config.d/banner.conf" >/dev/null
fi

sudo sed -i "s/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g; s/^#PermitEmptyPasswords no/PermitEmptyPasswords yes/g" ./build.$GLOBAL_BASEARCH/chroot/etc/ssh/sshd_config
