#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Setting up expert container.."

statusprint "Adding $CONTAINERUSERNAME's subuid and sudgid for unprivileged container.."
if ! grep -q "$CONTAINERUSERNAME:100000" ./build.$GLOBAL_BASEARCH/chroot/etc/subuid
then
  echo "$CONTAINERUSERNAME:100000:65536" | sudo tee -a ./build.$GLOBAL_BASEARCH/chroot/etc/subuid >/dev/null
  echo "$CONTAINERUSERNAME:100000:65536" | sudo tee -a ./build.$GLOBAL_BASEARCH/chroot/etc/subgid >/dev/null
fi

statusprint "Adding host setup script on boot.."
sudo cp -v resources/etc/systemd/system/host-setup.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/host-setup.service
sudo_file_template_copy resources/sbin/host-setup ./build.$GLOBAL_BASEARCH/chroot/sbin/host-setup
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/sbin/host-setup
sudo ln -s /etc/systemd/system/host-setup.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/host-setup.service 2>/dev/null

statusprint "Adding systemd-nspawn machine configuration.."
sudo mkdir -p ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/nspawn/
sudo cp -v ./resources/etc/systemd/nspawn/container.nspawn ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/nspawn/

sudo mkdir -p ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/systemd-nspawn@container.service.d 2>&-
sudo cp -v ./resources/etc/systemd/system/systemd-nspawn@container.service.d/override.conf ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/systemd-nspawn@container.service.d/

sudo mkdir -p ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/machines.target.wants 2>&-
sudo ln -fs /etc/systemd/system/systemd-nspawn@.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/machines.target.wants/systemd-nspawn@container.service 

sudo mkdir -p ./build.$GLOBAL_BASEARCH/chroot/var/lib/machines 2>&-
sudo ln -fs /opt/container/chroot.user ./build.$GLOBAL_BASEARCH/chroot/var/lib/machines/container 

statusprint "Adding container setup script.."
sudo cp -v resources/etc/systemd/system/container-setup.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/container-setup.service
sudo cp -v resources/sbin/container-setup ./build.$GLOBAL_BASEARCH/chroot/sbin/container-setup
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/sbin/container-setup
sudo ln -s /etc/systemd/system/container-setup.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/container-setup.service 2>/dev/null

statusprint "Adding historian service (container commands logger).."
sudo cp -v resources/etc/systemd/system/historian.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/historian.service
sudo cp -v resources/sbin/historian.sh ./build.$GLOBAL_BASEARCH/chroot/sbin/historian.sh
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/sbin/historian.sh
sudo ln -s /etc/systemd/system/historian.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/historian.service 2>/dev/null
sudo mkdir -p ./build.$GLOBAL_BASEARCH/chroot/usr/share/${PROJECTNAME}/etc/ 2>&-
sudo cp -v resources/etc/historian.profile ./build.$GLOBAL_BASEARCH/chroot/usr/share/${PROJECTNAME}/etc/historian.profile

statusprint "Adding iptables setup script.."
sudo_file_template_copy resources/sbin/host-iptables ./build.$GLOBAL_BASEARCH/chroot/sbin/host-iptables
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/sbin/host-iptables

statusprint "Adding privileged execution service and client.."
sudo cp -v resources/sbin/privexecd.sh ./build.$GLOBAL_BASEARCH/chroot/sbin/privexecd.sh
sudo cp -v resources/etc/systemd/system/privexec.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/privexec.service
sudo ln -s /etc/systemd/system/privexec.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/privexec.service 2>/dev/null
sudo cp -v resources/usr/bin/privexec ./build.$GLOBAL_BASEARCH/chroot/usr/bin/privexec
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/sbin/privexecd.sh ./build.$GLOBAL_BASEARCH/chroot/usr/bin/privexec

statusprint "Adding supervised execution service and client.."
sudo cp -v resources/sbin/supervised.sh ./build.$GLOBAL_BASEARCH/chroot/sbin/supervised.sh
sudo cp -v resources/etc/systemd/system/supervise.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/supervise.service
sudo ln -s /etc/systemd/system/supervise.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/supervise.service 2>/dev/null
sudo cp -v resources/usr/bin/supervised-shell ./build.$GLOBAL_BASEARCH/chroot/usr/bin/supervised-shell
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/sbin/supervised.sh ./build.$GLOBAL_BASEARCH/chroot/usr/bin/supervised-shell

statusprint "Adding memory watchdog.."
sudo cp -v resources/sbin/memwatchdog.sh ./build.$GLOBAL_BASEARCH/chroot/sbin/memwatchdog.sh
sudo cp -v resources/etc/systemd/system/memwatchdog.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/memwatchdog.service
sudo ln -s /etc/systemd/system/memwatchdog.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/memwatchdog.service 2>/dev/null
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/sbin/memwatchdog.sh


exit 0;
