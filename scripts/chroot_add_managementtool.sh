#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Adding management tool for system owner with autostart.."

statusprint "Adding Text-UI management and monitoring scripts.."
sudo_file_template_copy resources/usr/bin/${PROJECTSHORTNAME}-manage chroot/usr/bin/${PROJECTSHORTNAME}-manage
sudo chmod +x chroot/usr/bin/${PROJECTSHORTNAME}-manage

sudo_file_template_copy resources/usr/bin/${PROJECTSHORTNAME}-monitor chroot/usr/bin/${PROJECTSHORTNAME}-monitor
sudo chmod +x chroot/usr/bin/${PROJECTSHORTNAME}-monitor

sudo mkdir -p chroot/usr/share/${PROJECTNAME}
sudo_file_template_copy resources/usr/share/${PROJECTNAME}/introduction chroot/usr/share/${PROJECTNAME}/introduction

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
WantedBy=default.target" | sudo tee chroot/lib/systemd/system/${PROJECTSHORTNAME}-manage.service >/dev/null

sudo_file_template_copy resources/usr/share/${PROJECTNAME}/${PROJECTSHORTNAME}-manage.service chroot/usr/share/${PROJECTNAME}/${PROJECTSHORTNAME}-manage.service
sudo chmod +x chroot/usr/share/${PROJECTNAME}/${PROJECTSHORTNAME}-manage.service
sudo ln -s /lib/systemd/system/${PROJECTSHORTNAME}-manage.service chroot/etc/systemd/system/multi-user.target.wants/${PROJECTSHORTNAME}-manage.service 2>/dev/null

exit 0;
