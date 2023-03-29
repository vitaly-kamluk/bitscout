#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Setting network interface autoconfiguration timeout.."
sudo sed -i 's/^TimeoutStartSec=[0-9a-z]*$/TimeoutStartSec=1min/' ./build.$GLOBAL_BASEARCH/chroot/lib/systemd/system/networking.service 
sudo sed -i 's/^TimeoutStartSec=[0-9a-z]*$/TimeoutStartSec=10sec/' ./build.$GLOBAL_BASEARCH/chroot/lib/systemd/system/networking.service 

statusprint "Replacing networkd default configuration.."
sudo cp -v ./resources/etc/systemd/networkd.conf ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/

statusprint "Disabling intel_rapl module.."
if ! grep -q '^blacklist intel_rapl$' ./build.$GLOBAL_BASEARCH/chroot/etc/modprobe.d/blacklist.conf
then
  echo "blacklist intel_rapl" | sudo tee -a ./build.$GLOBAL_BASEARCH/chroot/etc/modprobe.d/blacklist.conf > /dev/null
fi

statusprint "Setting release name.."
sudo sed -i "s#Ubuntu 22.04[^ ]\{0,3\} LTS#${PROJECTNAME}#" ./build.$GLOBAL_BASEARCH/chroot/etc/issue.net ./build.$GLOBAL_BASEARCH/chroot/etc/lsb-release ./build.$GLOBAL_BASEARCH/chroot/etc/os-release
echo "${PROJECTNAME} (\m) \d \t \l" | sudo tee ./build.$GLOBAL_BASEARCH/chroot/etc/issue >/dev/null

statusprint "Removing extra banners and motd.."
sudo rm ./build.$GLOBAL_BASEARCH/chroot/etc/update-motd.d/* 2>/dev/null
cat /dev/null | sudo tee ./build.$GLOBAL_BASEARCH/chroot/etc/legal >/dev/null

statusprint "Setting up automounting for tmpfs.."
echo -e "tmpfs\t/tmp\ttmpfs\tnosuid,nodev\t0\t0" | sudo tee ./build.$GLOBAL_BASEARCH/chroot/etc/fstab >/dev/null

DEFTERM=xterm-color
statusprint "Setting default TERM to $DEFTERM.."
echo "TERM=$DEFTERM" | sudo tee ./build.$GLOBAL_BASEARCH/chroot/etc/profile.d/terminal.sh >/dev/null

statusprint "Adjusting colors and color schemes.."
sudo cp -v ./resources/etc/vtrgb ./build.$GLOBAL_BASEARCH/chroot/etc/console-setup/vtrgb.vga.${PROJECTSHORTNAME}
sudo ln -fs /etc/console-setup/vtrgb.vga.${PROJECTSHORTNAME} ./build.$GLOBAL_BASEARCH/chroot/etc/alternatives/vtrgb
sudo sed -i 's/^\(\s*\)PS1=.*/\1PS1='"'"'\${debian_chroot:\+(\$debian_chroot)}\\[\\e\[1;32m\\\]\\u\\\[\\033\[00m\\\]@\\\[\\e\[1;37;41m\\\]\\h\\\[\\033\[00m\\\]:\\\[\\033\[01;34m\\\]\\w\\\[\\033\[00m\\]\$ '"'"'/g' ./build.$GLOBAL_BASEARCH/chroot/etc/bash.bashrc ./build.$GLOBAL_BASEARCH/chroot/etc/skel/.bashrc
sudo cp -v ./resources/etc/dialogrc ./build.$GLOBAL_BASEARCH/chroot/etc/dialogrc

sudo cp -v ./build.$GLOBAL_BASEARCH/chroot/etc/dialogrc ./build.$GLOBAL_BASEARCH/chroot/etc/internet_off.dialogrc
sudo sed -i 's/screen_color = (CYAN,BLUE,ON)/screen_color = (CYAN,RED,ON)/g' ./build.$GLOBAL_BASEARCH/chroot/etc/internet_off.dialogrc

sudo rm -f ./build.$GLOBAL_BASEARCH/chroot/root/.bashrc ./build.$GLOBAL_BASEARCH/chroot/user/.bashrc

statusprint "Setting ulimit values.."
sudo cp -v ./resources/etc/security/limits.conf ./build.$GLOBAL_BASEARCH/chroot/etc/security/limits.conf

statusprint "Fixing sudo warning.." #should be removed in the future. see https://bugzilla.redhat.com/show_bug.cgi?id=1773148 
sudo cp -v ./resources/etc/sudo.conf ./build.$GLOBAL_BASEARCH/chroot/etc/

statusprint "Setting up network plan for container and the host.."
sudo cp -v ./resources/etc/netplan/{01-network-host.yaml,01-network-container.yaml} ./build.$GLOBAL_BASEARCH/chroot/etc/netplan/

statusprint "Setting up shell aliases.."
if ! grep -q '^#some shell aliases$' ./build.$GLOBAL_BASEARCH/chroot/etc/bash.bashrc
then
 echo "
#some shell aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'" | sudo tee -a ./build.$GLOBAL_BASEARCH/chroot/etc/bash.bashrc >/dev/null
fi

statusprint "Adding custom sysctl settings.."
sudo mkdir -p ./build.$GLOBAL_BASEARCH/chroot/etc/sysctl.d/ 2>&-
sudo cp -v ./resources/etc/sysctl.d/* ./build.$GLOBAL_BASEARCH/chroot/etc/sysctl.d/

statusprint "Safe-copying system-wide VIM configuration.."
[ ! -d "./build.$GLOBAL_BASEARCH/chroot/usr/share/vim" ] && sudo mkdir -p ./build.$GLOBAL_BASEARCH/chroot/usr/share/vim
chroot_safecopy_resources -v /resources/usr/share/vim/vimrc /usr/share/vim/vimrc
alias

exit 0;
