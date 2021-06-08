#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

VPNCFGDIR="config/openvpn"
VPNTEMPLATEDIR="resources/openvpn"
SYSTEM_EASYRSADIR="/usr/share/easy-rsa"

openvpn_template_copy()
{
  SRCFILE="$1"
  DSTFILE="$2"  
  sed "s/<PROJECTSHORTNAME>/${PROJECTSHORTNAME}/g; s/<OPENVPN_SERVER_EXTIP>/${GLOBAL_VPNSERVER}/g; s/<OPENVPN_SERVER_PORT>/${GLOBAL_VPNPORT}/g; s/<OPENVPN_SERVER_PROTOCOL>/${OPENVPN_SERVERPROTOCOL}/g; s/<OPENVPN_CLIENT_PROTOCOL>/${OPENVPN_CLIENTPROTOCOL}/g; s/<CRYPTOKEYSIZE>/${CRYPTOKEYSIZE}/g; s/<OPENVPN_IPPOOL_START>/$VPNNET_IPPOOLSTART/g; s/<OPENVPN_IPPOOL_END>/$VPNNET_IPPOOLEND/g; s/<OPENVPN_SERVER_IP>/$VPNNET_SERVERIP/g; s/<OPENVPN_CLIENT_IP>/$VPNNET_CLIENTIP/g; s/<OPENVPN_EXPERT_IP>/$VPNNET_EXPERTIP/g;" "$SRCFILE" > "$DSTFILE"
}

if [ -n "${GLOBAL_VPNTYPE}" -a "${GLOBAL_VPNTYPE}" = "openvpn" ]
then
  statusprint "Configuring OpenVPN.."

  if filelist_exists "$VPNCFGDIR/easy-rsa/pki/"{issued/client.crt,private/client.key,ca.crt,dh.pem,ta.key}
  then
    statusprint "Found existing keys. Using existing keys/config.."
  else
    statusprint "Preparing OpenVPN configs based on templates.."
    mkdir -p "$VPNCFGDIR" 2>&-
    export OPENVPN_SERVERPROTOCOL=${GLOBAL_VPNPROTOCOL}
    export OPENVPN_CLIENTPROTOCOL=${GLOBAL_VPNPROTOCOL}
    if [ "$GLOBAL_VPNPROTOCOL" == "tcp" ]
    then
      export OPENVPN_SERVERPROTOCOL="${GLOBAL_VPNPROTOCOL}-server"
      export OPENVPN_CLIENTPROTOCOL="${GLOBAL_VPNPROTOCOL}-client"
    fi

    openvpn_template_copy "$VPNTEMPLATEDIR/$PROJECTSHORTNAME.conf.expert" "$VPNCFGDIR/$PROJECTSHORTNAME.conf.expert"
    openvpn_template_copy "$VPNTEMPLATEDIR/$PROJECTSHORTNAME.conf.client" "$VPNCFGDIR/$PROJECTSHORTNAME.conf.client"
    openvpn_template_copy "$VPNTEMPLATEDIR/$PROJECTSHORTNAME.conf.server" "$VPNCFGDIR/$PROJECTSHORTNAME.conf.server"
    openvpn_template_copy "$VPNTEMPLATEDIR/ip_pool.lst" "$VPNCFGDIR/ip_pool.lst"

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
    EASYRSA_REQ_CN=${PROJECTNAME} ./easyrsa build-ca nopass
    EASYRSA_REQ_CN=server ./easyrsa gen-req server nopass
    EASYRSA_REQ_CN=client ./easyrsa gen-req client nopass
    EASYRSA_REQ_CN=expert ./easyrsa gen-req expert nopass
    ./easyrsa sign-req server server
    ./easyrsa sign-req client client
    ./easyrsa sign-req client expert
    ./easyrsa gen-dh
    openvpn --genkey --secret ./pki/ta.key

    cd "$PROJDIR"

  fi

  if ! [ -f "$VPNCFGDIR/${PROJECTSHORTNAME}.conf" ]
  then
    statusprint "Copying VPN client config to chroot.. Feel free to edit it in ./build.$GLOBAL_BASEARCH/chroot/etc/openvpn/client/${PROJECTSHORTNAME}.conf!"
    sudo cp -v "$VPNCFGDIR/${PROJECTSHORTNAME}.conf.client" "build.$GLOBAL_BASEARCH/chroot/etc/openvpn/client/${PROJECTSHORTNAME}.conf"
  fi

  statusprint "Copying essential files: certificates,keys.."
  sudo mkdir -p "build.$GLOBAL_BASEARCH/chroot/etc/openvpn/client/${PROJECTSHORTNAME}"
  sudo cp -v "$VPNCFGDIR/easy-rsa/pki/"{issued/client.crt,private/client.key,ca.crt,ta.key} "build.$GLOBAL_BASEARCH/chroot/etc/openvpn/client/${PROJECTSHORTNAME}/"

  statusprint "Enabling VPN client start on system boot.."
  sudo sed -i '/^AUTOSTART="[^"]*"$/d' ./build.$GLOBAL_BASEARCH/chroot/etc/default/openvpn
  echo "AUTOSTART=\"${PROJECTSHORTNAME}\"" | sudo tee -a ./build.$GLOBAL_BASEARCH/chroot/etc/default/openvpn >/dev/null
  chroot_exec build.$GLOBAL_BASEARCH/chroot "systemctl enable openvpn-client@${PROJECTSHORTNAME}.service"
else
  statusprint "Skipped OpenVPN configuration. VPN type is set to \"$GLOBAL_VPNTYPE\"."
fi

exit 0;
