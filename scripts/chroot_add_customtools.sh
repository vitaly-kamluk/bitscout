#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

statusprint "Adding custom tools to host system.."

statusprint "Adding Text-UI management script.."
sed "s/<PROJECTNAME>/${PROJECTNAME}/g; s/<PROJECTSHORTNAME>/${PROJECTSHORTNAME}/g; s/<CONTAINERNAME>/${CONTAINERNAME}/g; s/<CONTAINERUSERNAME>/${CONTAINERUSERNAME}/g;" resources/usr/bin/${PROJECTSHORTNAME}-manage | sudo tee chroot/usr/bin/${PROJECTSHORTNAME}-manage >/dev/null
sudo chmod +x chroot/usr/bin/${PROJECTSHORTNAME}-manage
sudo mkdir -p chroot/usr/share/${PROJECTNAME}
sed "s/<PROJECTNAME>/${PROJECTNAME}/g;" resources/usr/share/${PROJECTNAME}/introduction | sudo tee chroot/usr/share/${PROJECTNAME}/introduction > /dev/null

statusprint "Adding autostart of ${PROJECTSHORTNAME}-manage tool on tty.."
echo "[Unit]
Description=scount-manage on tty1
After=getty.target
Conflicts=getty@tty1.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/share/${PROJECTNAME}/${PROJECTSHORTNAME}-manage.service
ExecStop=/bin/kill -HUP ${MAINPID}
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
StandardInput=tty
StandardOutput=tty
StandardError=tty

[Install]
WantedBy=default.target" | sudo tee chroot/lib/systemd/system/${PROJECTSHORTNAME}-manage.service >/dev/null
sed "s/<PROJECTSHORTNAME>/${PROJECTSHORTNAME}/g;" resources/usr/share/${PROJECTNAME}/${PROJECTSHORTNAME}-manage.service | sudo tee chroot/usr/share/${PROJECTNAME}/${PROJECTSHORTNAME}-manage.service > /dev/null
sudo chmod +x chroot/usr/share/${PROJECTNAME}/${PROJECTSHORTNAME}-manage.service
sudo ln -s /lib/systemd/system/${PROJECTSHORTNAME}-manage.service chroot/etc/systemd/system/multi-user.target.wants/${PROJECTSHORTNAME}-manage.service 2>/dev/null

exit 0;
