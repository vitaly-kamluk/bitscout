#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

USERUID=999
USERGID=999

statusprint "Setting up isolated container.."

statusprint "Copying default LXC configuration.."
sudo mkdir -p "chroot/home/$CONTAINERUSERNAME/.local/share/lxc/$CONTAINERNAME"
sed "s/<CONTAINERNAME>/${CONTAINERNAME}/g; s/<CONTAINERUSERNAME>/${CONTAINERUSERNAME}/g;" resources/lxc/config/default.conf | sudo tee "chroot/home/$CONTAINERUSERNAME/.local/share/lxc/$CONTAINERNAME/config" >/dev/null
sudo chown -R $USERUID:$USERGID chroot/home/$CONTAINERUSERNAME

statusprint "Adding $CONTAINERUSERNAME's subuid and sudgid for unprivileged container.."
if ! grep -q "$CONTAINERUSERNAME:100000" chroot/etc/subuid
then
  echo "$CONTAINERUSERNAME:100000:65537" | sudo tee -a chroot/etc/subuid >/dev/null
  echo "$CONTAINERUSERNAME:100000:65537" | sudo tee -a chroot/etc/subgid >/dev/null
fi

statusprint "Permitting $CONTAINERUSERNAME to access LXC bridge.."
if ! grep -q "^$CONTAINERUSERNAME veth" chroot/etc/lxc/lxc-usernet
then
  echo "$CONTAINERUSERNAME veth lxcbr0 10" | sudo tee -a chroot/etc/lxc/lxc-usernet 2>/dev/null
fi

statusprint "Setting up fixed LXC container IP via dnsmasq.."
sudo cp -v resources/lxc/config/lxc-net chroot/etc/default/
echo "dhcp-hostsfile=/etc/lxc/dnsmasq-hosts.conf" | sudo tee chroot/etc/lxc/dnsmasq.conf >/dev/null
echo "${PROJECTNAME},10.0.3.2" | sudo tee chroot/etc/lxc/dnsmasq-hosts.conf >/dev/null

statusprint "Adding systemd task to setup host system on startup.."
sudo cp -v resources/systemd/host-setup.service chroot/lib/systemd/system/host-setup.service
sed "s/<CONTAINERUSERNAME>/${CONTAINERUSERNAME}/g; s/<CONTAINERNAME>/${CONTAINERNAME}/g; s/<PROJECTNAME>/${PROJECTNAME}/g; s/<PROJECTSHORTNAME>/${PROJECTSHORTNAME}/g;" resources/sbin/host-setup | sudo tee chroot/sbin/host-setup >/dev/null
sudo chmod +x chroot/sbin/host-setup
sudo ln -s /lib/systemd/system/host-setup.service chroot/etc/systemd/system/multi-user.target.wants/host-setup.service 2>/dev/null

statusprint "Adding systemd task to setup the container on LXC start.."
sudo cp -v resources/systemd/container-setup.service chroot/lib/systemd/system/container-setup.service
sudo cp -v resources/sbin/container-setup chroot/sbin/container-setup
sudo chmod +x chroot/sbin/container-setup
sudo ln -s /lib/systemd/system/container-setup.service chroot/etc/systemd/system/multi-user.target.wants/container-setup.service 2>/dev/null

statusprint "Adding systemd task to start historian service (container commands logger) on LXC start.."
sudo cp -v resources/systemd/historian.service chroot/lib/systemd/system/historian.service
sudo cp -v resources/sbin/historian.sh chroot/sbin/historian.sh
sudo chmod +x chroot/sbin/historian.sh
sudo ln -s /lib/systemd/system/historian.service chroot/etc/systemd/system/multi-user.target.wants/historian.service 2>/dev/null
sudo mkdir -p chroot/usr/share/${PROJECTNAME}/etc/ 2>&-
sudo cp -v resources/etc/historian.profile chroot/usr/share/${PROJECTNAME}/etc/historian.profile


statusprint "Adding iptables setup script.."
sudo cp resources/sbin/host-iptables chroot/sbin/host-iptables
sudo chmod +x chroot/sbin/host-iptables
sudo ln -s /sbin/host-iptables chroot/etc/network/if-pre-up.d/firewall 2>&-

exit 0;
