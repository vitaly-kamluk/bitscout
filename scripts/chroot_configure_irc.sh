#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

IRCTEMPLATEDIR="resources/irssi"

statusprint "Copying client irssi configuration.."
sudo cp -v "$IRCTEMPLATEDIR/irssi.conf.client" chroot/etc/irssi.conf

exit 0;
