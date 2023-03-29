#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

# This add a systemd unit called "internet_indicator.service" amd respectrive timer
# The purpose is to run periodic internet connectivity test (every 30s)
# This test can be disabled via bitscout management tool NETWORK->DISABLE INTERNET TEST

. ./scripts/functions

statusprint "Adding internet-indicator script.."
sudo_file_template_copy ./resources/usr/bin/internet-indicator.sh ./build.$GLOBAL_BASEARCH/chroot/usr/bin/internet-indicator.sh
sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/usr/bin/internet-indicator.sh

statusprint "Setting up internet-indicator service and timer.."
sudo_file_template_copy ./resources/etc/systemd/system/internet-indicator.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/internet-indicator.service
sudo ln -s /etc/systemd/system/internet-indicator.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/internet-indicator.service 2>/dev/null

sudo_file_template_copy ./resources/etc/systemd/system/internet-indicator.timer ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/internet-indicator.timer
sudo ln -s /etc/systemd/system/internet-indicator.timer ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/internet-indicator.timer 2>/dev/null

exit 0;
