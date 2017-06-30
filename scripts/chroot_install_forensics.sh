#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

./scripts/chroot_enter.sh

statusprint "Installing forensics packages in chroot.."
runinchroot 'DEBIAN_FRONTEND=noninteractive apt-get --yes install dcfldd sleuthkit plaso yara gddrescue hexedit'

./scripts/chroot_leave.sh
exit 0;
