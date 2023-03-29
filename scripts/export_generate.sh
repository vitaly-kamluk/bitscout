#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

EXPSERVER="exports/server"
EXPEXPERT="exports/expert"

statusprint "Generating export files packages.."

statusprint "Copying files for the server.."

if [ -d "./config/openvpn" ]
then
  mkdir -p "$EXPSERVER/etc/openvpn/${PROJECTSHORTNAME}" 2>&-
  cp -v "./config/openvpn/${PROJECTSHORTNAME}.conf.server" "$EXPSERVER/etc/openvpn/${PROJECTSHORTNAME}.conf"
  cp -v "./config/openvpn/ip_pool.lst" "$EXPSERVER/etc/openvpn/${PROJECTSHORTNAME}/"
  cp -v "./config/openvpn/easy-rsa/pki/"{ta.key,dh.pem,private/server.key,issued/server.crt,ca.crt} "$EXPSERVER/etc/openvpn/${PROJECTSHORTNAME}/"
fi

if [ -d "./config/wireguard" ]
then
  mkdir -p "$EXPSERVER/etc/wireguard" 2>&-
  cp -v "./config/wireguard/${PROJECTSHORTNAME}.conf.server" "$EXPSERVER/etc/wireguard/${PROJECTSHORTNAME}.conf"
fi

mkdir -p "$EXPSERVER/etc/ngircd" 2>&-; cp -v "./config/ngircd/ngircd.conf" "$EXPSERVER/etc/ngircd/"

statusprint "Copying files for the expert.."
mkdir -p "$EXPEXPERT/etc/openvpn/${PROJECTSHORTNAME}"
mkdir -p "$EXPEXPERT/etc/"{ssh,irc}

if [ -d "./config/openvpn" ]
then
  mkdir -p "$EXPEXPERT/etc/openvpn/${PROJECTSHORTNAME}"
  cp -v "./config/openvpn/${PROJECTSHORTNAME}.conf.expert" "$EXPEXPERT/etc/openvpn/${PROJECTSHORTNAME}.conf"
  cp -v "./config/openvpn/easy-rsa/pki/"{ta.key,private/expert.key,issued/expert.crt,ca.crt} "$EXPEXPERT/etc/openvpn/${PROJECTSHORTNAME}/"
fi

if [ -d "./config/wireguard" ]
then
  mkdir -p "$EXPEXPERT/etc/wireguard" 2>&-
  cp -v "./config/wireguard/${PROJECTSHORTNAME}.conf.expert" "$EXPEXPERT/etc/wireguard/${PROJECTSHORTNAME}.conf"
fi

cp -v "./config/ssh/"{${PROJECTSHORTNAME},${PROJECTSHORTNAME}.pub} "$EXPEXPERT/etc/ssh"
sed 's/owner/expert/g;' "./config/irssi/irssi.conf" > "$EXPEXPERT/etc/irc/irssi.conf"

sudo [ -d ./build.$GLOBAL_BASEARCH/chroot/var/lib/tor/tor_hidden_service/ ] && sudo mkdir -p $EXPEXPERT/var/lib/tor && sudo cp -r ./build.$GLOBAL_BASEARCH/chroot/var/lib/tor $EXPEXPERT/var/lib/tor
[ $? == '0' ] && statusprint "[SUCCESS] Copying tor config file and key to host success..."

exit 0;
