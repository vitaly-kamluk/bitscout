#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

VPNCFGDIR="config/openvpn"
VPNTEMPLATEDIR="resources/openvpn"
SYSTEM_EASYRSADIR="/usr/share/easy-rsa"

statusprint "Configuring OpenVPN.."

if filelist_exists "$VPNCFGDIR/easy-rsa/pki/"{issued/client.crt,private/client.key,ca.crt,dh.pem,ta.key}
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

  statusprint "Preparing Easy-RSA 3 settings.."
  cp -v "$VPNCFGDIR/easy-rsa/vars.example" "$VPNCFGDIR/easy-rsa/vars"
  PROJDIR=`pwd`
  echo "set_var EASYRSA_PKI            \"pki\"
set_var EASYRSA_BATCH            \"1\"
set_var EASYRSA            \".\"
" > "$VPNCFGDIR/easy-rsa/vars"

  statusprint "Patching easy-rsa tools to enable non-interactive mode by default."
  find "$VPNCFGDIR/easy-rsa/" -maxdepth 1 -type f | grep -v "pkitool" | while read f; do sed -i 's/--interact/--batch/g' "$f"; done

  statusprint "Creating certificate authority and server+client certificates.."
  mkdir -p "$VPNCFGDIR/easy-rsa/pki"
  cd "$VPNCFGDIR/easy-rsa/"
  dd if=/dev/urandom of=./pki/.rnd bs=1024 count=1

  ./easyrsa init-pki
  ./easyrsa build-ca nopass
  ./easyrsa gen-req server nopass
  ./easyrsa gen-req client nopass
  ./easyrsa gen-req expert nopass
  ./easyrsa sign-req server server
  ./easyrsa sign-req client client
  ./easyrsa sign-req client expert
  ./easyrsa gen-dh
  openvpn --genkey --secret ./pki/ta.key

  cd "$PROJDIR"

fi

if ! [ -f "$VPNCFGDIR/${PROJECTSHORTNAME}.conf" ]
then
  statusprint "Copying VPN client config to chroot.. Feel free to edit it in ./build.$GLOBAL_BASEARCH/chroot/etc/openvpn/${PROJECTSHORTNAME}.conf!"
  sudo cp -v "$VPNCFGDIR/${PROJECTSHORTNAME}.conf.client" "build.$GLOBAL_BASEARCH/chroot/etc/openvpn/${PROJECTSHORTNAME}.conf"
fi

statusprint "Copying essential files: certificates,keys.."
sudo mkdir -p "build.$GLOBAL_BASEARCH/chroot/etc/openvpn/${PROJECTSHORTNAME}"
sudo cp -v "$VPNCFGDIR/easy-rsa/pki/"{issued/client.crt,private/client.key,ca.crt,ta.key} "build.$GLOBAL_BASEARCH/chroot/etc/openvpn/${PROJECTSHORTNAME}/"

statusprint "Enabling VPN client start on system boot.."
sudo sed -i '/^AUTOSTART="[^"]*"$/d' ./build.$GLOBAL_BASEARCH/chroot/etc/default/openvpn
echo "AUTOSTART=\"${PROJECTSHORTNAME}\"" | sudo tee -a ./build.$GLOBAL_BASEARCH/chroot/etc/default/openvpn >/dev/null


exit 0;
