#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

VPNCFGDIR="config/openvpn"
VPNTEMPLATEDIR="resources/openvpn"
SYSTEM_EASYRSADIR="/usr/share/easy-rsa"

statusprint "Configuring OpenVPN.."

if filelist_exists "$VPNCFGDIR/easy-rsa/keys/"{${PROJECTSHORTNAME}.crt,${PROJECTSHORTNAME}.key,ca.crt,dh${CRYPTOKEYSIZE}.pem,ta.key}
then
  statusprint "Found existing keys. Using existing keys/config.."
else
  statusprint "Preparing OpenVPN configs based on templates.."
  mkdir -p "$VPNCFGDIR" 2>&-
  SERVERPROTOCOL=${GLOBAL_VPNPROTOCOL}
  CLIENTPROTOCOL=${GLOBAL_VPNPROTOCOL}
  if [ "$GLOBAL_VPNPROTOCOL" == "tcp" ]
  then
    SERVERPROTOCOL="${GLOBAL_VPNPROTOCOL}-server"
    CLIENTPROTOCOL="${GLOBAL_VPNPROTOCOL}-client"
  fi
  sed "s/<PROJECTSHORTNAME>/${PROJECTSHORTNAME}/g; s/<SERVER_IP>/${GLOBAL_VPNSERVER}/g; s/<SERVER_PORT>/${GLOBAL_VPNPORT}/g; s/<SERVER_PROTOCOL>/${CLIENTPROTOCOL}/g; s/<CRYPTOKEYSIZE>/${CRYPTOKEYSIZE}/g;" "$VPNTEMPLATEDIR/$PROJECTSHORTNAME.conf.client" > "$VPNCFGDIR/$PROJECTSHORTNAME.conf.client"
  sed "s/<PROJECTSHORTNAME>/${PROJECTSHORTNAME}/g; s/<SERVER_IP>/${GLOBAL_VPNSERVER}/g; s/<SERVER_PORT>/${GLOBAL_VPNPORT}/g; s/<SERVER_PROTOCOL>/${CLIENTPROTOCOL}/g; s/<CRYPTOKEYSIZE>/${CRYPTOKEYSIZE}/g;" "$VPNTEMPLATEDIR/$PROJECTSHORTNAME.conf.expert" > "$VPNCFGDIR/$PROJECTSHORTNAME.conf.expert"
  sed "s/<PROJECTSHORTNAME>/${PROJECTSHORTNAME}/g; s/<SERVER_IP>/${GLOBAL_VPNSERVER}/g; s/<SERVER_PORT>/${GLOBAL_VPNPORT}/g; s/<SERVER_PROTOCOL>/${SERVERPROTOCOL}/g; s/<CRYPTOKEYSIZE>/${CRYPTOKEYSIZE}/g;" "$VPNTEMPLATEDIR/$PROJECTSHORTNAME.conf.server" > "$VPNCFGDIR/$PROJECTSHORTNAME.conf.server"
  cp -v "$VPNTEMPLATEDIR/ip_pool.lst" "$VPNCFGDIR/ip_pool.lst"

  statusprint "Setting up OpenVPN client.."
  if ! [ -d "$VPNCFGDIR/easy-rsa" ]
  then
    statusprint "Couldn't find existing Easy-RSA directory in $VPNCFGDIR."
    install_required_package easy-rsa
  fi

  if ! [ -d "$SYSTEM_EASYRSADIR"  ]
  then
    statusprint "Couldn't find required easy-rsa directory.. Aborting."
    exit 1
  fi

  statusprint "Copying easy-rsa directory to local configs subdirectory.."
  cp -r "$SYSTEM_EASYRSADIR" "$VPNCFGDIR/"

  statusprint "Editing default easy-rsa settings.."
  PROJDIR=`pwd`
  sed -i 's,^export KEY_DIR=.*,export KEY_DIR="'"$PROJDIR/$VPNCFGDIR"'/easy-rsa/keys",; s,^export KEY_COUNTRY=.*,export KEY_COUNTRY="NA",;  s,^export KEY_PROVINCE=.*,export KEY_PROVINCE="n/a",;  s,^export KEY_CITY=.*,export KEY_CITY="n/a",; s,^export KEY_ORG=.*,export KEY_ORG="'${PROJECTNAME}'",;  s,^export KEY_EMAIL=.*,export KEY_EMAIL="n/a",;  s,^export KEY_OU=.*,export KEY_OU="n/a",;  s,^export KEY_SIZE=.*,export KEY_SIZE='${CRYPTOKEYSIZE}',;  s,^export CA_EXPIRE=.*,export CA_EXPIRE=1095,;  s,^export KEY_EXPIRE=.*,export KEY_EXPIRE=365,; '  "$VPNCFGDIR/easy-rsa/vars" 

  statusprint "Patching easy-rsa tools to enable non-interactive mode by default."
  find "$VPNCFGDIR/easy-rsa/" -maxdepth 1 -type f | grep -v "pkitool" | while read f; do sed -i 's/--interact/--batch/g' "$f"; done

  #TODO: Update this when there will be openvpn/easy-rsa/openssl-1.1.0.cnf
  statusprint "Symlinking openssl.cnf file to openssl-1.0.0.cnf"
  sudo ln -fs "openssl-1.0.0.cnf" "$VPNCFGDIR/easy-rsa/openssl.cnf"

  statusprint "Creating certificate authority and server+client certificates.."
  mkdir -p "$VPNCFGDIR/easy-rsa/keys"
  cd "$VPNCFGDIR/easy-rsa/"
  . "./vars"
  ./clean-all
  install_required_package openvpn
  openvpn --genkey --secret ./keys/ta.key
  ./build-ca
  ./build-dh
  ./build-key-server ${PROJECTSHORTNAME}server
  ./build-key $PROJECTSHORTNAME
  ./build-key expert
  cd "$PROJDIR"

fi

if ! [ -f "$VPNCFGDIR/${PROJECTSHORTNAME}.conf" ]
then
  statusprint "Copying VPN client config to chroot.. Feel free to edit it in chroot/etc/openvpn/${PROJECTSHORTNAME}.conf!"
  sudo cp -v "$VPNCFGDIR/${PROJECTSHORTNAME}.conf.client" "chroot/etc/openvpn/${PROJECTSHORTNAME}.conf"
fi

statusprint "Copying essential files: certificates,keys.."
sudo mkdir -p "chroot/etc/openvpn/${PROJECTSHORTNAME}"
sudo cp -v "$VPNCFGDIR/easy-rsa/keys/"{${PROJECTSHORTNAME}.crt,${PROJECTSHORTNAME}.key,ca.crt,dh${CRYPTOKEYSIZE}.pem,ta.key} "chroot/etc/openvpn/${PROJECTSHORTNAME}/"

statusprint "Enabling VPN client start on system boot.."
sudo sed -i '/^AUTOSTART="[^"]*"$/d' ./chroot/etc/default/openvpn
echo "AUTOSTART=\"${PROJECTSHORTNAME}\"" | sudo tee -a ./chroot/etc/default/openvpn >/dev/null


exit 0;
