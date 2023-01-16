#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

#This script file will allow the bitscout to create a
#Systemd unit called "internet_indicator.service" to check
#If there is an internet connection

#ExecStart=/usr/share/${PROJECTNAME}/internet-indicator.service start
#ExecStop=/usr/share/${PROJECTNAME}/internet-indicator.service stop

. ./scripts/functions

statusprint "Adding internet indicator management script.."
sudo_file_template_copy resources/usr/bin/internet-indicator.sh ./build.$GLOBAL_BASEARCH/chroot/usr/bin/internet-indicator.sh
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/usr/bin/internet-indicator.sh

statusprint "Adding autostart of internet-indicator.service.."

echo "[Unit]
Description=internet_indicator on bitscout management tool
After=networking.service

[Service]
Type=simple

ExecStart=/usr/bin/internet-indicator.sh start
ExecStop=/usr/bin/internet-indicator.sh stop

[Install]
WantedBy=multi-user.target" | sudo tee ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/internet-indicator.service >/dev/null

sudo_file_template_copy resources/usr/share/${PROJECTNAME}/internet-indicator.service ./build.$GLOBAL_BASEARCH/chroot/usr/share/${PROJECTNAME}/internet-indicator.service
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/usr/share/${PROJECTNAME}/internet-indicator.service
sudo ln -s /etc/systemd/system/internet-indicator.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/internet-indicator.service 2>/dev/null



statusprint "Adding internet-indicator.timer.."

echo "[Unit]
Description=internet_indicator on bitscout management tool
Requires=internet-indicator.service

[Timer]
Unit=internet-indicator.service
OnCalendar=*:*:0/30
AccuracySec=1sec


[Install]
WantedBy=timers.target" | sudo tee ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/internet-indicator.timer >/dev/null

sudo_file_template_copy resources/usr/share/${PROJECTNAME}/internet-indicator.timer ./build.$GLOBAL_BASEARCH/chroot/usr/share/${PROJECTNAME}/internet-indicator.timer
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/usr/share/${PROJECTNAME}/internet-indicator.timer
sudo ln -s /etc/systemd/system/internet-indicator.timer ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/internet-indicator.timer 2>/dev/null

exit 0;