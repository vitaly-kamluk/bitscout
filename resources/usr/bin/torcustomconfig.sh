#!/bin/bash

sudo chown -R debian-tor:debian-tor /etc/tor

sudo chown -R debian-tor:debian-tor /var/lib/tor

systemd-run --machine container systemctl stop tor

systemd-run --machine container systemctl disable tor
