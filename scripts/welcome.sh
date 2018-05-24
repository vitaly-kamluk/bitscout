#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

BUILDCONFPATH="config/${PROJECTNAME}-build.conf"

statusprint "Welcome to $PROJECTNAME builder!"
HOSTUNAME=$(uname -a)
HOSTDIST=$(lsb_release -a 2>&-)
COMMIT=$(git log -1 2>&-|head -n1)
statusprint "Host OS info:\n$HOSTUNAME\n$HOSTDIST\nUsing git $COMMIT"

validate_vpnhostname()
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

validate_vpnport()
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

if ! [ -f "$BUILDCONFPATH" ]
then
  statusprint "It seems that you are at fresh build environment.\nWe need to populate the config with some essential data.\nPlease answer the following questions or put your existing build config to config/$PROJECTNAME-build.conf."
  PRINTOPTIONS=n statusprint "Proceed to interactive settings? [Y/n]: "
  read choice
  if [ ! -z "$choice" -a ! "${choice^}" == "Y" ] 
  then
  echo "Build process aborted."
    exit 1
  else
    mkdir config 2>&-

    releasesize=""
    while ! validate_releasesize "$releasesize"
    do
      PRINTOPTIONS=n statusprint "${PROJECTNAME} may be built to be compact or normal.\nPlease choose option number:\n 1. compact - minimal size, less tools and drivers. <300Mb\n 2. normal - includes most common forensic tools,drivers,etc. <400Mb\n 3. maximal - includes maximum of forensic tools and frameworks. <750Mb\n Your choice (1|2|3): "
      read releasesize
      if ! validate_releasesize "$releasesize"
      then
        statusprint "Invalid input data format. Please try again.."
      fi
    done

    customkernel="0"
    PRINTOPTIONS=n statusprint "If you are going to deal with badly unmounted filesystems, software RAID or LVM, it is recommended to apply kernel write-blocker patch for extra care of the evidence. However, please note that it may take 3-4 hours to rebuild the kernel on a single core CPU.\nWould you like to build and use kernel with write-blocker? [Y/n]: "
    read choice
    if [ -z "$choice" -o "${choice^}" == "Y" ]
    then
      customkernel="1"
    else
      customkernel="0"
    fi

    vpnhost=""
    vpnprotocol=""
    vpnport=""
    while ! validate_vpnhostname "$vpnhost" && ! validate_vpnprotocol "$vpnprotocol" && ! validate_vpnport "$vpnport"
    do
      statusprint "To use ${PROJECTNAME} remotely you will need a VPN server."
      PRINTOPTIONS=n statusprint "Please enter your designated VPN server protocol (udp/tcp), host and port. You can change it later.\nExamples:\n udp://127.0.0.1:2222\n tcp://myvpnserver:8080\nYour input: "
      read vpnuri
      mapfile -t VPNCFG < <( echo "$vpnuri" | sed 's#^\(udp\|tcp\)://\([a-zA-Z0-9_.-]*\):\([0-9]\{1,5\}\)$#\2\n\1\n\3#' )
      vpnhost="${VPNCFG[0]}"
      vpnprotocol="${VPNCFG[1]}"
      vpnport="${VPNCFG[2]}"

      if ! validate_vpnhostname "$vpnhost" && ! validate_vpnprotocol "$vpnprotocol" && ! validate_vpnport "$vpnport"
      then
        statusprint "Invalid input data format. Please try again.."
      fi
    done

    buildid=`dd if=/dev/urandom bs=1 count=4 2>&- | xxd -pos`
    
    statusprint "Saving configuration.."
    echo "GLOBAL_RELEASESIZE=\"$releasesize\"
GLOBAL_VPNSERVER=\"$vpnhost\"
GLOBAL_VPNPROTOCOL=\"$vpnprotocol\"
GLOBAL_VPNPORT=\"$vpnport\"
GLOBAL_BUILDID=\"$buildid\"
GLOBAL_CUSTOMKERNEL=\"$customkernel\" 
GLOBAL_BASEARCH=\"amd64\"
#GLOBAL_BASEARCH=\"i386\"
CRYPTOKEYSIZE=2048" > "$BUILDCONFPATH"
  fi
fi

exit 0;
