#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

openvpn_template_copy()
{
  SRCFILE="$1"
  DSTFILE="$2"
  [ ! -d "${DSTFILE%/*}" ] && $SUDO mkdir -p "${DSTFILE%/*}"
  echo "'$SRCFILE' -> '$DSTFILE'"
  sed "s/<PROJECTSHORTNAME>/${PROJECTSHORTNAME}/g; s/<OPENVPN_SERVER_EXTIP>/${GLOBAL_VPNSERVER}/g; s/<OPENVPN_SERVER_PORT>/${GLOBAL_VPNPORT}/g; s/<OPENVPN_SERVER_PROTOCOL>/${OPENVPN_SERVERPROTOCOL}/g; s/<OPENVPN_CLIENT_PROTOCOL>/${OPENVPN_CLIENTPROTOCOL}/g; s/<CRYPTOKEYSIZE>/${CRYPTOKEYSIZE}/g; s/<OPENVPN_IPPOOL_START>/$VPNNET_IPPOOLSTART/g; s/<OPENVPN_IPPOOL_END>/$VPNNET_IPPOOLEND/g; s/<OPENVPN_SERVER_IP>/$VPNNET_SERVERIP/g; s/<OPENVPN_CLIENT_IP>/$VPNNET_CLIENTIP/g; s/<OPENVPN_EXPERT_IP>/$VPNNET_EXPERTIP/g;" "$SRCFILE" > "$DSTFILE"
}

wireguard_template_copy()
{
  SRCFILE="$1"  
  DSTFILE="$2"
  [ ! -d "${DSTFILE%/*}" ] && $SUDO mkdir -p "${DSTFILE%/*}"
  echo "'$SRCFILE' -> '$DSTFILE'"

  #Escaping + and / in base64 values for sed embedding:
  ESC_WIREGUARD_PRESHARED_KEY=$( echo "$WIREGUARD_PRESHARED_KEY" | sed 's#\([+/]\)#\\\1#g' )

  ESC_WIREGUARD_SERVER_PRIVATE_KEY=$( echo "$WIREGUARD_SERVER_PRIVATE_KEY" | sed 's#\([+/]\)#\\\1#g' )
  ESC_WIREGUARD_SERVER_PUBLIC_KEY=$( echo "$WIREGUARD_SERVER_PUBLIC_KEY" | sed 's#\([+/]\)#\\\1#g' )

  ESC_WIREGUARD_CLIENT_PRIVATE_KEY=$( echo "$WIREGUARD_CLIENT_PRIVATE_KEY" | sed 's#\([+/]\)#\\\1#g' )
  ESC_WIREGUARD_CLIENT_PUBLIC_KEY=$( echo "$WIREGUARD_CLIENT_PUBLIC_KEY" | sed 's#\([+/]\)#\\\1#g' )

  ESC_WIREGUARD_EXPERT_PRIVATE_KEY=$( echo "$WIREGUARD_EXPERT_PRIVATE_KEY" | sed 's#\([+/]\)#\\\1#g' )
  ESC_WIREGUARD_EXPERT_PUBLIC_KEY=$( echo "$WIREGUARD_EXPERT_PUBLIC_KEY" | sed 's#\([+/]\)#\\\1#g' )

  sed "s#<PROJECTSHORTNAME>#${PROJECTSHORTNAME}#g; s#<WIREGUARD_SERVER_EXTIP>#${GLOBAL_VPNSERVER}#g; s#<WIREGUARD_SERVER_PORT>#${GLOBAL_VPNPORT}#g; s#<WIREGUARD_VPNNET>#$VPNNET#g; s#<WIREGUARD_VPNNET_SERVER_IP>#$VPNNET_SERVERIP#g; s#<WIREGUARD_VPNNET_CLIENT_IP>#$VPNNET_CLIENTIP#g; s#<WIREGUARD_VPNNET_EXPERT_IP>#$VPNNET_EXPERTIP#g; s#<WIREGUARD_SERVER_PRIVATE_KEY>#$ESC_WIREGUARD_SERVER_PRIVATE_KEY#g; s#<WIREGUARD_SERVER_PUBLIC_KEY>#$ESC_WIREGUARD_SERVER_PUBLIC_KEY#g; s#<WIREGUARD_CLIENT_PRIVATE_KEY>#$ESC_WIREGUARD_CLIENT_PRIVATE_KEY#g; s#<WIREGUARD_CLIENT_PUBLIC_KEY>#$ESC_WIREGUARD_CLIENT_PUBLIC_KEY#g; s#<WIREGUARD_EXPERT_PRIVATE_KEY>#$ESC_WIREGUARD_EXPERT_PRIVATE_KEY#g; s#<WIREGUARD_EXPERT_PUBLIC_KEY>#$ESC_WIREGUARD_EXPERT_PUBLIC_KEY#g; s#<WIREGUARD_PRESHARED_KEY>#$ESC_WIREGUARD_PRESHARED_KEY#g;" "$SRCFILE" > "$DSTFILE"
}


if [ -n "${GLOBAL_VPNTYPE}" -a "${GLOBAL_VPNTYPE}" = "openvpn" ]; then
  VPNCFGDIR="config/openvpn"
  VPNTEMPLATEDIR="resources/openvpn"
  SYSTEM_EASYRSADIR="/usr/share/easy-rsa"

  statusprint "Configuring OpenVPN.."

  if filelist_exists "$VPNCFGDIR/easy-rsa/pki/"{issued/client.crt,private/client.key,ca.crt,dh.pem,ta.key}; then
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
    if ! [ -d "$VPNCFGDIR/easy-rsa" ]; then
      statusprint "Couldn't find existing Easy-RSA directory in $VPNCFGDIR."
      install_required_package easy-rsa
    fi

    if ! [ -d "$SYSTEM_EASYRSADIR" ]; then
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

  sudo mkdir -p "build.$GLOBAL_BASEARCH/chroot/etc/openvpn/client/${PROJECTSHORTNAME}"
  
  if [ -f "$VPNCFGDIR/${PROJECTSHORTNAME}.conf.client" ]; then
    statusprint "Copying VPN client config to chroot.. Feel free to edit it in ./build.$GLOBAL_BASEARCH/chroot/etc/openvpn/client/${PROJECTSHORTNAME}.conf!"
    sudo cp -v "$VPNCFGDIR/${PROJECTSHORTNAME}.conf.client" "build.$GLOBAL_BASEARCH/chroot/etc/openvpn/client/${PROJECTSHORTNAME}.conf"
  fi

  statusprint "Copying essential files: certificates,keys.."
  sudo cp -v "$VPNCFGDIR/easy-rsa/pki/"{issued/client.crt,private/client.key,ca.crt,ta.key} "build.$GLOBAL_BASEARCH/chroot/etc/openvpn/client/${PROJECTSHORTNAME}/"

  statusprint "Enabling VPN client start on system boot.."
  sudo sed -i '/^AUTOSTART="[^"]*"$/d' ./build.$GLOBAL_BASEARCH/chroot/etc/default/openvpn
  echo "AUTOSTART=\"${PROJECTSHORTNAME}\"" | sudo tee -a ./build.$GLOBAL_BASEARCH/chroot/etc/default/openvpn >/dev/null
  chroot_exec build.$GLOBAL_BASEARCH/chroot "systemctl enable openvpn-client@${PROJECTSHORTNAME}.service"
elif [ -n "${GLOBAL_VPNTYPE}" -a "${GLOBAL_VPNTYPE}" = "wireguard" ]; then
  VPNCFGDIR="config/wireguard"
  VPNTEMPLATEDIR="resources/wireguard"

  install_required_package "wireguard-tools"

  if filelist_exists "$VPNCFGDIR/"{$PROJECTSHORTNAME.conf.server,$PROJECTSHORTNAME.conf.client,$PROJECTSHORTNAME.conf.expert}; then
    statusprint "Found existing config files. Skipping config generation.."
  else
    statusprint "Preparing wireguard configs based on templates.."
    mkdir -p "$VPNCFGDIR" 2>&-

    statusprint "Configuring Wireguard.."
    WIREGUARD_PRESHARED_KEY=$( wg genpsk )

    WIREGUARD_SERVER_PRIVATE_KEY=$( wg genkey )
    WIREGUARD_SERVER_PUBLIC_KEY=$( echo "$WIREGUARD_SERVER_PRIVATE_KEY" | wg pubkey )

    WIREGUARD_CLIENT_PRIVATE_KEY=$( wg genkey )
    WIREGUARD_CLIENT_PUBLIC_KEY=$( echo "$WIREGUARD_CLIENT_PRIVATE_KEY" | wg pubkey )

    WIREGUARD_EXPERT_PRIVATE_KEY=$( wg genkey )
    WIREGUARD_EXPERT_PUBLIC_KEY=$( echo "$WIREGUARD_EXPERT_PRIVATE_KEY" | wg pubkey )

    wireguard_template_copy "$VPNTEMPLATEDIR/wg0.conf.expert" "$VPNCFGDIR/$PROJECTSHORTNAME.conf.expert"
    wireguard_template_copy "$VPNTEMPLATEDIR/wg0.conf.client" "$VPNCFGDIR/$PROJECTSHORTNAME.conf.client"
    wireguard_template_copy "$VPNTEMPLATEDIR/wg0.conf.server" "$VPNCFGDIR/$PROJECTSHORTNAME.conf.server"

  fi
  statusprint "Installing wireguard clienf configuration.."
  if [ -f "$VPNCFGDIR/${PROJECTSHORTNAME}.conf.client" ]; then
    [ ! -d "./build.$GLOBAL_BASEARCH/chroot/etc/wireguard/" ] && sudo mkdir -p "./build.$GLOBAL_BASEARCH/chroot/etc/wireguard/"
    statusprint "Copying VPN client config to chroot.. Feel free to edit it in ./build.$GLOBAL_BASEARCH/chroot/etc/wireguard/${PROJECTSHORTNAME}.conf"
    sudo cp -v "$VPNCFGDIR/${PROJECTSHORTNAME}.conf.client" "build.$GLOBAL_BASEARCH/chroot/etc/wireguard/${PROJECTSHORTNAME}.conf"
  fi

  statusprint "Enabling wireguard on system boot.."
  chroot_exec build.$GLOBAL_BASEARCH/chroot "systemctl enable wg-quick@${PROJECTSHORTNAME}.service"

elif [ -n "${GLOBAL_VPNTYPE}" -a "${GLOBAL_VPNTYPE}" = "tor" ]; then

  statusprint "Installing TOR in main host..."
  sudo apt install tor
  [ $? == '0' ] && statusprint "[SUCCESS] Installing TOR in main host"

  statusprint "CHECKING TOR CONFIGURATIONS DIRECTORY AND FILES...%."

  while true
  do
      sleep 5
      [ -f /etc/tor/torrc ] && statusprint "[SUCCESS] TORRC FILE CREATED!"
      [ ! -f /etc/tor/torrc ] && statusprint "[FAILED] TORRC FILE NOT CREATED!"

      sudo [ -f /var/lib/tor/cached-certs ] && statusprint "[SUCCESS] CACHED-CERTS FILE CREATED!"
      sudo [ ! -f /var/lib/tor/cached-certs ] && statusprint "[FAILED] CACHED-CERTS FILE NOT CREATED!"
      
      sudo [ -f /var/lib/tor/cached-microdesc-consensus ] && statusprint "[SUCCESS] CACHED-MICRODESC-CONSENSUS FILE CREATED!"
      sudo [ ! -f /var/lib/tor/cached-microdesc-consensus ] && statusprint "[FAILED] CACHED-MICRODESC-CONSENSUS FILE NOT CREATED!"

      sudo [ -f /var/lib/tor/cached-microdescs.new ] && statusprint "[SUCCESS] CACHED-MICRODESCS.NEW FILE CREATED!"
      sudo [ ! -f /var/lib/tor/cached-microdescs.new ] && statusprint "[FAILED] CACHED-MICRODESCS.NEW FILE NOT CREATED!"

      sudo [ -d /var/lib/tor/keys ] && statusprint "[SUCCESS] KEYS DIRECTORY CREATED!"
      sudo [ ! -d /var/lib/tor/keys ] && statusprint "[FAILED] KEYS DIRECTORY NOT CREATED!"

      sudo [ -f /var/lib/tor/lock ] && statusprint "[SUCCESS] LOCK FILE CREATED!"
      sudo [ ! -f /var/lib/tor/lock ] && statusprint "[FAILED] LOCK FILE NOT CREATED!"

      sudo [ -f /var/lib/tor/state ] && statusprint "[SUCCESS] STATE FILE CREATED!"
      sudo [ ! -f /var/lib/tor/state ] && statusprint "[FAILED] STATE FILE NOT CREATED!"

      echo "====================="

      [ -f /etc/tor/torrc ] && sudo [ -f /var/lib/tor/cached-certs ] && sudo [ -f /var/lib/tor/cached-microdesc-consensus ] && sudo [ -f /var/lib/tor/cached-microdescs.new ] && sudo [ -d /var/lib/tor/keys ] && sudo [ -f /var/lib/tor/lock ] && sudo [ -f /var/lib/tor/state ] && statusprint "COMPLETED!" && break;
  done

  statusprint "Backup the main host tor directory to tmp..."

  statusprint "Create a tmp directory for backup..."

  [ -d /tmp/torBackup ] && statusprint "Folder exist, need to be purged and created new one" && rm -r /tmp/torBackup && mkdir -p /tmp/torBackup
  [ $? == '0' ] && statusprint "[SUCCESS]Purging and creating a new folder is success..."
  [ ! -d /tmp/torBackup ] && statusprint "Folder do not exist, need to created directory" && mkdir -p /tmp/torBackup
  [ $? == '0' ] && statusprint "[SUCCESS] Creating a new folder..."

  statusprint "Copying /var/lib/tor to backup location..."
  sudo cp -r /var/lib/tor /tmp/torBackup/torVar
  [ $? == '0' ] && statusprint "[SUCCESS] Copying /var/lib/tor to torBackup directory..."

  statusprint "Copying /etc/tor to backup location..."
  sudo cp -r /etc/tor /tmp/torBackup/torEtc
  [ $? == '0' ] && statusprint "[SUCCESS] Copying /etc/tor to backup location..."

  statusprint "Modify the TORRC file"

  sudo echo "HiddenServiceDir /var/lib/tor/tor_hidden_service/
  HiddenServicePort 22 10.3.0.2:22
	HiddenServicePort 23 10.3.0.1:22 
  HiddenServiceAuthorizeClient stealth tor_hidden_service" | sudo tee /etc/tor/torrc

  [ $? == '0' ] && statusprint "[SUCCESS] modifying the torrc file"

  statusprint "Change the owner for the /etc/tor directory..."
  sudo chown -R debian-tor:debian-tor /etc/tor
  [ $? == '0' ] && statusprint "[SUCCESS] changing the owner for the /etc/tor directory..."

  statusprint "Change the owner for the /var/lib/tor directory..."
  sudo chown -R debian-tor:debian-tor /var/lib/tor
  [ $? == '0' ] && statusprint "[SUCCESS] Changeingthe owner for the /var/lib/tor directory..."

  statusprint "Restart TOR service to generate the hostname and etc..."
  sudo systemctl restart tor
  [ $? == '0' ] && statusprint "[SUCCESS] Restart TOR service to generate the hostname and etc..."

  echo "CHECKING TOR CONFIGURATIONS DIRECTORY AND FILES...%."

  while true
  do
      sleep 5
      [ -f /etc/tor/torrc ] && statusprint "[SUCCESS] TORRC FILE CREATED!"
      [ ! -f /etc/tor/torrc ] && statusprint "[FAILED] TORRC FILE NOT CREATED!"

      sudo [ -f /var/lib/tor/cached-certs ] && statusprint "[SUCCESS] CACHED-CERTS FILE CREATED!"
      sudo [ ! -f /var/lib/tor/cached-certs ] && statusprint "[FAILED] CACHED-CERTS FILE NOT CREATED!"
      
      sudo [ -f /var/lib/tor/cached-microdesc-consensus ] && statusprint "[SUCCESS] CACHED-MICRODESC-CONSENSUS FILE CREATED!"
      sudo [ ! -f /var/lib/tor/cached-microdesc-consensus ] && statusprint "[FAILED] CACHED-MICRODESC-CONSENSUS FILE NOT CREATED!"

      sudo [ -f /var/lib/tor/cached-microdescs.new ] && statusprint "[SUCCESS] CACHED-MICRODESCS.NEW FILE CREATED!"
      sudo [ ! -f /var/lib/tor/cached-microdescs.new ] && statusprint "[FAILED] CACHED-MICRODESCS.NEW FILE NOT CREATED!"

      sudo [ -d /var/lib/tor/keys ] && statusprint "[SUCCESS] KEYS DIRECTORY CREATED!"
      sudo [ ! -d /var/lib/tor/keys ] && statusprint "[FAILED] KEYS DIRECTORY NOT CREATED!"

      sudo [ -f /var/lib/tor/lock ] && statusprint "[SUCCESS] LOCK FILE CREATED!"
      sudo [ ! -f /var/lib/tor/lock ] && statusprint "[FAILED] LOCK FILE NOT CREATED!"

      sudo [ -f /var/lib/tor/state ] && statusprint "[SUCCESS] STATE FILE CREATED!"
      sudo [ ! -f /var/lib/tor/state ] && statusprint "[FAILED] STATE FILE NOT CREATED!"

      sudo [ -f /var/lib/tor/cached-microdescs ] && statusprint "[SUCCESS] CACHED-MICRODESCS FILE CREATED!"
      sudo [ ! -f /var/lib/tor/cached-microdescs ] && statusprint "[FAILED] CACHED-MICRODESCS FILE NOT CREATED!"

      sudo [ -d /var/lib/tor/tor_hidden_service ] && statusprint "[SUCCESS] TOR_HIDDEN_SERVICE FOLDER CREATED!"
      sudo [ ! -d /var/lib/tor/tor_hidden_service ] && statusprint "[FAILED] TOR_HIDDEN_SERVICE FOLDER FILE NOT CREATED!"
      
      echo "====================="

      [ -f /etc/tor/torrc ] && sudo [ -f /var/lib/tor/cached-certs ] && sudo [ -f /var/lib/tor/cached-microdesc-consensus ] && sudo [ -f /var/lib/tor/cached-microdescs.new ] && sudo [ -d /var/lib/tor/keys ] && sudo [ -f /var/lib/tor/lock ] && sudo [ -f /var/lib/tor/state ] && sudo [ -f /var/lib/tor/cached-microdescs ] && sudo [ -d /var/lib/tor/tor_hidden_service ] && statusprint "COMPLETED!" && break;
  done

  sudo [ -d ./build.$GLOBAL_BASEARCH/chroot/var/lib/tor ] && sudo rm -r ./build.$GLOBAL_BASEARCH/chroot/var/lib/tor;

  statusprint "Copying TOR configuration files from /var/lib/tor  to bitscout build..."
  sudo cp -r /var/lib/tor ./build.$GLOBAL_BASEARCH/chroot/var/lib/tor
  [ $? == '0' ] && statusprint "[SUCCESS] Copying TOR configuration files from /var/lib/tor  to bitscout build..." 

  sudo [ -d ./build.$GLOBAL_BASEARCH/chroot/etc/tor/ ] && sudo rm -r ./build.$GLOBAL_BASEARCH/chroot/etc/tor/

  statusprint "Copying TOR configuration files from  /etc/tor to bitscout build..."
  sudo cp -r /etc/tor ./build.$GLOBAL_BASEARCH/chroot/etc/tor
  [ $? == '0' ] && statusprint "[SUCCESS] Copying TOR configuration files from  /etc/tor to bitscout build..." 

  sudo [ ! -f ./build.$GLOBAL_BASEARCH/chroot/var/lib/tor/tor_hidden_service/hostname ] && statusprint "Failed to generate TOR service file"
  sudo [ -f ./build.$GLOBAL_BASEARCH/chroot/var/lib/tor/tor_hidden_service/hostname ] && statusprint "[SUCCESS] Success to generate TOR service file"

  statusprint "Removing the current TOR configurations from the main host with the backup in tmp directory"

  statusprint "Replacing /etc/tor with backup file..."
  sudo rm -r /etc/tor && sudo cp -r /tmp/torBackup/torEtc /etc/tor
  [ $? == '0' ] && statusprint "[SUCCESS] Replacing /etc/tor"

  statusprint "Replacing /var/lib/tor with backup file..."
  sudo rm -r /var/lib/tor && sudo cp -r /tmp/torBackup/torVar /var/lib/tor
  [ $? == '0' ] && statusprint "[SUCCESS] Replacing /var/lib/tor"

  sudo_file_template_copy resources/usr/bin/torcustomconfig.sh ./build.$GLOBAL_BASEARCH/chroot/usr/bin/torcustomconfig.sh
  sudo chmod +x ./build.$GLOBAL_BASEARCH/chroot/usr/bin/torcustomconfig.sh

  echo "[Unit]
  Description=custom configuration for tor
  StartLimitIntervalSec=10
  StartLimitBurst=5

  [Service]
  ExecStart=/usr/bin/torcustomconfig.sh
  Restart=on-failure
  RestartSec=2s

  [Install]
  WantedBy=multi-user.target" | sudo tee ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/torcustomconfig.service >/dev/null

  sudo ln -s /etc/systemd/system/torcustomconfig.service ./build.$GLOBAL_BASEARCH/chroot/etc/systemd/system/multi-user.target.wants/torcustomconfig.service 2>/dev/null

  statusprint "Removing tmp directory for tor..."
  sudo [ -d /tmp/torBackup ] && sudo rm -r /tmp/torBackup
  [ $? == '0' ] && statusprint "[SUCCESS] removing tor backup directory in tmp"

else
  statusprint "Skipped VPN configuration. VPN type is set to \"$GLOBAL_VPNTYPE\"."
fi

exit 0;
