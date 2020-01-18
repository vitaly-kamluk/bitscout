#!/bin/bash
if [ -z "$CHROOTDIR" ]
then
  echo "Specify CHROOTDIR environment variable."
  exit 1
else
  systemd-nspawn --bind=/sys/fs/cgroup --bind=/dev/fuse --property DeviceAllow='/dev/fuse rwm' -D "$CHROOTDIR" /sbin/init
fi
