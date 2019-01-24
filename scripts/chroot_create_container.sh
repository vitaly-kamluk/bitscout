#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Setting up LXD container.."

statusprint "Adding $CONTAINERUSERNAME's subuid and sudgid for unprivileged container.."
if ! grep -q "$CONTAINERUSERNAME:100000" ./build.$GLOBAL_BASEARCH/chroot/etc/subuid
then
  echo "$CONTAINERUSERNAME:100000:65536" | sudo tee -a ./build.$GLOBAL_BASEARCH/chroot/etc/subuid >/dev/null
  echo "$CONTAINERUSERNAME:100000:65536" | sudo tee -a ./build.$GLOBAL_BASEARCH/chroot/etc/subgid >/dev/null
fi

statusprint "Adding systemd task to setup host on boot.."
sudo cp -v resources/systemd/host-setup.service ./build.$GLOBAL_BASEARCH/chroot/lib/systemd/system/host-setup.service
sudo_file_template_copy resources/sbin/host-setup ./build.$GLOBAL_BASEARCH/chroot/sbin/host-setup
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/sbin/host-setup
sudo ln -s /lib/systemd/system/host-setup.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/host-setup.service 2>/dev/null

statusprint "Adding systemd task to setup the container on start.."
sudo cp -v resources/systemd/container-setup.service ./build.$GLOBAL_BASEARCH/chroot/lib/systemd/system/container-setup.service
sudo cp -v resources/sbin/container-setup ./build.$GLOBAL_BASEARCH/chroot/sbin/container-setup
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/sbin/container-setup
sudo ln -s /lib/systemd/system/container-setup.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/container-setup.service 2>/dev/null

statusprint "Adding systemd task to start historian service (container commands logger) on LXC start.."
sudo cp -v resources/systemd/historian.service ./build.$GLOBAL_BASEARCH/chroot/lib/systemd/system/historian.service
sudo cp -v resources/sbin/historian.sh ./build.$GLOBAL_BASEARCH/chroot/sbin/historian.sh
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/sbin/historian.sh
sudo ln -s /lib/systemd/system/historian.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/historian.service 2>/dev/null
sudo mkdir -p ./build.$GLOBAL_BASEARCH/chroot/usr/share/${PROJECTNAME}/etc/ 2>&-
sudo cp -v resources/etc/historian.profile ./build.$GLOBAL_BASEARCH/chroot/usr/share/${PROJECTNAME}/etc/historian.profile

statusprint "Adding iptables setup script.."
sudo_file_template_copy resources/sbin/host-iptables ./build.$GLOBAL_BASEARCH/chroot/sbin/host-iptables
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/sbin/host-iptables
sudo ln -s /sbin/host-iptables ./build.$GLOBAL_BASEARCH/chroot/etc/network/if-pre-up.d/firewall 2>&-

statusprint "Adding privileged execution service and client.."
sudo cp resources/sbin/privexecd.sh ./build.$GLOBAL_BASEARCH/chroot/sbin/privexecd.sh
sudo cp resources/systemd/privexec.service ./build.$GLOBAL_BASEARCH/chroot/lib/systemd/system/privexec.service
sudo ln -s /lib/systemd/system/privexec.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/privexec.service 2>/dev/null
sudo cp resources/usr/bin/privexec ./build.$GLOBAL_BASEARCH/chroot/usr/bin/privexec
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/sbin/privexecd.sh ./build.$GLOBAL_BASEARCH/chroot/usr/bin/privexec

statusprint "Adding supervised execution service and client.."
sudo cp resources/sbin/supervised.sh ./build.$GLOBAL_BASEARCH/chroot/sbin/supervised.sh
sudo cp resources/systemd/supervise.service ./build.$GLOBAL_BASEARCH/chroot/lib/systemd/system/supervise.service
sudo ln -s /lib/systemd/system/supervise.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/supervise.service 2>/dev/null
sudo cp resources/usr/bin/supervised-shell ./build.$GLOBAL_BASEARCH/chroot/usr/bin/supervised-shell
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/sbin/supervised.sh ./build.$GLOBAL_BASEARCH/chroot/usr/bin/supervised-shell


exit 0;
