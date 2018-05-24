#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

EXPSERVER="exports/server"
EXPEXPERT="exports/expert"

statusprint "Generating export files packages.."

statusprint "Copying files for the server.."
mkdir -p "$EXPSERVER/etc/openvpn/${PROJECTSHORTNAME}" 2>&-
cp -v "./config/openvpn/${PROJECTSHORTNAME}.conf.server" "$EXPSERVER/etc/openvpn/${PROJECTSHORTNAME}.conf"
cp -v "./config/openvpn/ip_pool.lst" "$EXPSERVER/etc/openvpn/${PROJECTSHORTNAME}/"
cp -v "./config/openvpn/easy-rsa/keys/"{ta.key,dh${CRYPTOKEYSIZE}.pem,"${PROJECTSHORTNAME}server.key","${PROJECTSHORTNAME}server.crt",ca.crt} "$EXPSERVER/etc/openvpn/${PROJECTSHORTNAME}/"
mkdir -p "$EXPSERVER/etc/ngircd" 2>&-; cp -v "./config/ngircd/ngircd.conf" "$EXPSERVER/etc/ngircd/"

statusprint "Copying files for the expert host.."
mkdir -p "$EXPEXPERT/etc/openvpn/${PROJECTSHORTNAME}"
mkdir -p "$EXPEXPERT/etc/"{ssh,irc}
cp -v "./config/openvpn/${PROJECTSHORTNAME}.conf.expert" "$EXPEXPERT/etc/openvpn/${PROJECTSHORTNAME}.conf"
cp -v "./config/openvpn/easy-rsa/keys/"{ta.key,dh${CRYPTOKEYSIZE}.pem,expert.key,expert.crt,ca.crt} "$EXPEXPERT/etc/openvpn/${PROJECTSHORTNAME}/"
cp -v "./config/ssh/"{${PROJECTSHORTNAME},${PROJECTSHORTNAME}.pub} "$EXPEXPERT/etc/ssh"
sed 's/owner/expert/g;' "./config/irssi/irssi.conf" > "$EXPEXPERT/etc/irc/irssi.conf"

exit 0;
