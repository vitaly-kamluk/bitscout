#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Setting network interface autoconfiguration timeout.."
sudo sed -i 's/^TimeoutStartSec=[0-9a-z]*$/TimeoutStartSec=1min/' chroot/lib/systemd/system/networking.service 
sudo sed -i 's/^TimeoutStartSec=[0-9a-z]*$/TimeoutStartSec=10sec/' chroot/lib/systemd/system/networking.service 

statusprint "Disabling intel_rapl module.."
if ! grep -q '^blacklist intel_rapl$' chroot/etc/modprobe.d/blacklist.conf
then
  echo "blacklist intel_rapl" | sudo tee -a chroot/etc/modprobe.d/blacklist.conf > /dev/null
fi

statusprint "Setting release name.."
sudo sed -i "s#Ubuntu 18.04[^ ]\{0,3\} LTS#${PROJECTNAME}#" chroot/etc/issue.net chroot/etc/lsb-release chroot/etc/os-release
echo "${PROJECTNAME} (\m) \d \t \l" | sudo tee chroot/etc/issue >/dev/null

statusprint "Removing extra banners and motd.."
sudo rm chroot/etc/update-motd.d/* 2>/dev/null
cat /dev/null | sudo tee chroot/etc/legal >/dev/null

statusprint "Setting up automounting for tmpfs.."
echo -e "tmpfs\t/tmp\ttmpfs\tnosuid,nodev\t0\t0" | sudo tee chroot/etc/fstab >/dev/null

DEFTERM=xterm-color
statusprint "Setting default TERM to $DEFTERM.."
echo "TERM=$DEFTERM" | sudo tee chroot/etc/profile.d/terminal.sh >/dev/null

statusprint "Adjusting colors and color schemes.."
sudo cp -v ./resources/etc/vtrgb chroot/etc/console-setup/vtrgb.vga.${PROJECTSHORTNAME}
sudo ln -fs /etc/console-setup/vtrgb.vga.${PROJECTSHORTNAME} ./chroot/etc/alternatives/vtrgb
sudo sed -i 's/^\(\s*\)PS1=.*/\1PS1='"'"'\${debian_chroot:\+(\$debian_chroot)}\\[\\e\[1;32m\\\]\\u\\\[\\033\[00m\\\]@\\\[\\e\[1;37;41m\\\]\\h\\\[\\033\[00m\\\]:\\\[\\033\[01;34m\\\]\\w\\\[\\033\[00m\\]\$ '"'"'/g' chroot/etc/bash.bashrc chroot/etc/skel/.bashrc
sudo cp -v ./resources/etc/dialogrc ./chroot/etc/dialogrc
sudo rm -f ./chroot/root/.bashrc ./chroot/user/.bashrc

statusprint "Copying WiFi manager default configuration file.."
sudo mkdir -p ./chroot/etc/wicd/ &&
sudo cp -v ./resources/etc/wicd/manager-settings.conf ./chroot/etc/wicd/manager-settings.conf

statusprint "Setting ulimit values.."
sudo cp -v ./resources/etc/security/limits.conf ./chroot/etc/security/limits.conf

statusprint "Setting up shell aliases.."
if ! grep -q '^#some shell aliases$' chroot/etc/bash.bashrc
then
 echo "
#some shell aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'" | sudo tee -a chroot/etc/bash.bashrc >/dev/null
fi

exit 0;
