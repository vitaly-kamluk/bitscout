#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

BUILDCONFPATH="config/${PROJECTNAME}-build.conf"
CONFIGNAME={"GLOBAL_RELEASESIZE"}

statusprint "Welcome to $PROJECTNAME builder!"
HOSTUNAME=$(uname -a)
HOSTDIST=$(lsb_release -a 2>&-)
COMMIT=$(git log -1 2>&-|head -n1)
statusprint "Host OS info:\n$HOSTUNAME\n$HOSTDIST\nUsing git $COMMIT"

validate_hostaddr()
{
  if [ -n "$1" ]
  then
    echo "$1" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$|^[^.-][a-z0-9_.-]*[^.-]$'
    return $?
  else
    return 1
  fi
}

validate_vpnprotocol()
{
  echo "$1" | grep -qE "^udp$|^tcp$"
  return $?
}

validate_portnum()
{
  if [ -n "$1" ]
  then
    test $1 -gt 0 -a $1 -lt 65536;
    return $?
  else
    return 1
  fi
}

validate_releasesize()
{
  if [ -n "$1" ]
  then
     test $1 -ge 1 -a $1 -le 3;
     return $?
  else
     return 1;
  fi
}

validate_buildarch()
{
    if [ "$1" = "amd64" ] || [ "$1" = "i386" ]
    then
        return $?
    else
        return 1

    fi 
}

msg_new_config_opt="\nSome new options were not found in your config file, please answer the following question(s)\nand it will be appended to your existing config file located in config/$PROJECTNAME-build.conf.\n"

if ! [ -f "$BUILDCONFPATH" ]
then
  statusprint "It seems that you are at fresh build environment.\nWe need to populate the config with some essential data.\nPlease answer the following questions or put your existing build config to config/$PROJECTNAME-build.conf."
  PRINTOPTIONS=n statusprint "Proceed to interactive settings? [Y/n]: "
  read choice
  if [ ! -z "$choice" -a ! "${choice^}" = "Y" ] 
  then
  echo "Build process aborted."
    exit 1
  else
    mkdir config 2>&-
  fi
fi

if [ -z "$GLOBAL_RELEASESIZE" ]
then
    if  [ -f "$BUILDCONFPATH" ]; then PRINTOPTIONS=n statusprint "$msg_new_config_opt"; fi
    releasesize=""
    while ! validate_releasesize "$releasesize"
    do
      PRINTOPTIONS=n statusprint "${PROJECTNAME} may be built to be compact or normal.\nPlease choose option number:\n 1. compact - minimal size, less tools and drivers.\n 2. normal - includes most common forensic tools, drivers, etc.\n 3. maximal - includes maximum of forensic tools and frameworks.\n Your choice (1|2|3): "
      read releasesize
      if ! validate_releasesize "$releasesize"
      then
        statusprint "Invalid input data format. Please try again.."
      fi
    done
fi

if [ -z "$GLOBAL_CUSTOMKERNEL" ] 
then
    if  [ -f "$BUILDCONFPATH" ]; then PRINTOPTIONS=n statusprint "$msg_new_config_opt"; fi
    customkernel="0"
    PRINTOPTIONS=n statusprint "If you are going to deal with badly unmounted filesystems, software RAID or LVM, it is recommended to apply kernel write-blocker patch for extra care of the evidence. However, please note that this is eperimental feature and may take 3-4 hours to rebuild the kernel on a single-core CPU.\nWould you like to build and use kernel with write-blocker? [y/N]: "
    read choice
    if [ -z "$choice" -o "${choice^}" = "N" -o -o "${choice^}" = "n" ]
    then
      customkernel="0"
    else
      customkernel="1"
    fi

fi

if [ -z "$GLOBAL_VPNSERVER" ] || [ -z "$GLOBAL_VPNPROTOCOL" ] || [ -z "$GLOBAL_VPNPORT" ]
then
    if  [ -f "$BUILDCONFPATH" ]; then PRINTOPTIONS=n statusprint "$msg_new_config_opt"; fi
    vpnhost=""
    vpnprotocol=""
    vpnport=""
    while ! validate_hostaddr "$vpnhost" && ! validate_vpnprotocol "$vpnprotocol" && ! validate_portnum "$vpnport"
    do
      statusprint "To use ${PROJECTNAME} remotely you will need a VPN server."
      PRINTOPTIONS=n statusprint "Please enter your designated VPN server protocol (udp/tcp), host and port. You can change it later.\nExamples:\n udp://127.0.0.1:2222\n tcp://myvpnserver:8080\nYour input: "
      read vpnuri
      mapfile -t VPNCFG < <( echo "$vpnuri" | sed 's#^\(udp\|tcp\)://\([a-zA-Z0-9_.-]*\):\([0-9]\{1,5\}\)$#\2\n\1\n\3#' )
      vpnhost="${VPNCFG[0]}"
      vpnprotocol="${VPNCFG[1]}"
      vpnport="${VPNCFG[2]}"

      if ! validate_hostaddr "$vpnhost" && ! validate_vpnprotocol "$vpnprotocol" && ! validate_portnum "$vpnport"
      then
        statusprint "Invalid input data format. Please try again.."
      fi
    done
    if ( [ -n "$GLOBAL_VPNSERVER" ] || [ -n "$GLOBAL_VPNPROTOCOL" ] || [ -n "$GLOBAL_VPNPORT" ] ) &&  [ -f "$BUILDCONFPATH" ]
    then
       echo "GLOBAL_VPNSERVER=\"$vpnhost\"
GLOBAL_VPNPROTOCOL=\"$vpnprotocol\"
GLOBAL_VPNPORT=\"$vpnport\"" >> "$BUILDCONFPATH"

    fi
fi

if [ -z "$GLOBAL_SYSLOGSERVER" ]
then
    if  [ -f "$BUILDCONFPATH" ]; then PRINTOPTIONS=n statusprint "$msg_new_config_opt"; fi
    sysloghost=""
    while ! validate_hostaddr "$sysloghost"
    do
        statusprint "It is recommended to configure a remote syslog server (can be the VPN server) to log shell commands."
        PRINTOPTIONS=n statusprint "Please enter the syslog server address.\nIf you do not intend using remote logging of commands simply press Enter.\nYour input [syslog server address]: "
        read sysloghost
        if [ "$sysloghost" = "" ]
        then
            sysloghost="none"
            statusprint "Remote syslog support is not used."
            [ -f "$BUILDCONFPATH" ] && echo "GLOBAL_SYSLOGSERVER=\"$sysloghost\"" >> "$BUILDCONFPATH"
            break
        fi
        if ! validate_hostaddr "$sysloghost"
        then
            statusprint "Invalid input data format. Please try again.."
        fi
    done
    if [ -n "$GLOBAL_SYSLOGSERVER" ] && [ "$sysloghost" != "" ] && [ -f "$BUILDCONFPATH" ]
    then
        echo "GLOBAL_SYSLOGSERVER=\"$sysloghost\"" >> "$BUILDCONFPATH"
    fi
fi

if [ -z "$GLOBAL_BUILDID" ]
then    
    if  [ -f "$BUILDCONFPATH" ]; then PRINTOPTIONS=n statusprint "$msg_new_config_opt"; fi
    buildid=`dd if=/dev/urandom bs=1 count=4 2>&- | xxd -pos`
    if [ -n "$GLOBAL_BUILDID" ] &&  [ -f "$BUILDCONFPATH" ]; then
        echo "GLOBAL_BUILDID=\"$buildid\"" >> "$BUILDCONFPATH"
    fi
fi

if [ -z "$CRYPTOKEYSIZE" ] && [ -f "$BUILDCONFPATH" ]
then
    echo "CRYPTOKEYSIZE=2048" >> "$BUILDCONFPATH"
fi

if [ -z "$GLOBAL_BASEARCH" ] 
then
    if  [ -f "$BUILDCONFPATH" ]; then PRINTOPTIONS=n statusprint "$msg_new_config_opt"; fi
    buildarch=""
    while ! validate_buildarch "$buildarch"
    do
        echo "$buildarch"
        PRINTOPTIONS=n statusprint "You have an option to build this image in the following architecture\n1. 64-bit architecture (amd64)\n2. 32-bit architecture (i386)\nPlease make your choice [1 or 2]: "
        read choice
        
        if [ "$choice" = "1" ]
        then
            buildarch="amd64"
        elif [ "$choice" = "2" ]
        then
            buildarch="i386"
        fi
    
        if ! validate_buildarch "$buildarch"
        then
            statusprint "Invalid input choice. Please try again.."
        fi
    done
    
    if [ -z "$GLOBAL_BASEARCH" ] && [ -f "$BUILDCONFPATH" ]
    then
        echo "GLOBAL_BASEARCH=\"$buildarch\" #amd64 (64bit) or i386 (32-bit)"  >> "$BUILDCONFPATH"
    fi

fi


if ! [ -f "$BUILDCONFPATH" ]
then
    statusprint "Saving configuration.."
    echo "GLOBAL_RELEASESIZE=\"$releasesize\"
GLOBAL_HOSTSSH_ENABLED=0 #set to 1 to enable direct SSH access to the host system (port 23)
GLOBAL_LANACCESS_ENABLED=0 #set to 1 to enable access from LAN after boot
GLOBAL_VPNSERVER=\"$vpnhost\"
GLOBAL_VPNPROTOCOL=\"$vpnprotocol\"
GLOBAL_VPNPORT=\"$vpnport\"
GLOBAL_SYSLOGSERVER=\"$sysloghost\"
GLOBAL_BUILDID=\"$buildid\"
GLOBAL_CUSTOMKERNEL=\"$customkernel\" 
GLOBAL_BASEARCH=\"$buildarch\" #amd64 (64bit) or i386 (32-bit)
CRYPTOKEYSIZE=2048" > "$BUILDCONFPATH"

    PRINTOPTIONS=n statusprint "Configuration saved. Continue? [Y/n]: "
    read choice
    if [ -z "$choice" -o "${choice^}" = "Y" ]
    then
      exit 0;
    else
      exit 1;
    fi


fi
exit 0;
