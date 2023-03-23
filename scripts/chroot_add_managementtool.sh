#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Adding management tool for system owner with autostart.."
statusprint "Installing remote access packages in chroot.."
chroot_exec build.$GLOBAL_BASEARCH/chroot 'DEBIAN_FRONTEND=noninteractive;
aria2c(){ /usr/bin/aria2c --console-log-level=warn "$@";}; export -f aria2c;
apt-get --yes install pwgen'

statusprint "Adding Text-UI management and monitoring scripts.."
sudo_file_template_copy resources/usr/bin/${PROJECTSHORTNAME}-manage ./build.$GLOBAL_BASEARCH/chroot/usr/bin/${PROJECTSHORTNAME}-manage
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/usr/bin/${PROJECTSHORTNAME}-manage

sudo_file_template_copy resources/usr/bin/${PROJECTSHORTNAME}-monitor ./build.$GLOBAL_BASEARCH/chroot/usr/bin/${PROJECTSHORTNAME}-monitor
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/usr/bin/${PROJECTSHORTNAME}-monitor

sudo mkdir -p ./build.$GLOBAL_BASEARCH/chroot/usr/share/${PROJECTNAME}
sudo_file_template_copy resources/usr/share/${PROJECTNAME}/introduction ./build.$GLOBAL_BASEARCH/chroot/usr/share/${PROJECTNAME}/introduction

statusprint "Adding autostart of ${PROJECTSHORTNAME}-manage tool on tty.."
echo "[Unit]
Description=${PROJECTSHORTNAME}-manage on tty2
After=getty.target networking.service host-system.service
Conflicts=getty@tty2.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/share/${PROJECTNAME}/${PROJECTSHORTNAME}-manage.service
ExecStop=/bin/kill -HUP ${MAINPID}
TTYPath=/dev/tty2
TTYReset=yes
TTYVHangup=yes
StandardInput=tty
StandardOutput=tty
StandardError=tty

[Install]
WantedBy=default.target" | sudo tee ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/${PROJECTSHORTNAME}-manage.service >/dev/null

sudo_file_template_copy resources/usr/share/${PROJECTNAME}/${PROJECTSHORTNAME}-manage.service ./build.$GLOBAL_BASEARCH/chroot/usr/share/${PROJECTNAME}/${PROJECTSHORTNAME}-manage.service
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/usr/share/${PROJECTNAME}/${PROJECTSHORTNAME}-manage.service
sudo ln -s /etc/systemd/system/${PROJECTSHORTNAME}-manage.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/${PROJECTSHORTNAME}-manage.service 2>/dev/null


statusprint "Adding container management scripts.."
sudo cp -v resources/usr/bin/container-{suspend,resume}.sh ./build.$GLOBAL_BASEARCH/chroot/usr/bin/
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/usr/bin/container-{suspend,resume}.sh

exit 0;
