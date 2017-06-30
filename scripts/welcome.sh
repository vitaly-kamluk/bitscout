#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

BUILDCONFPATH="config/${PROJECTNAME}-build.conf"

statusprint "Welcome to $PROJECTNAME 2.0 builder!"

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

if ! [ -f "$BUILDCONFPATH" ]
then
  statusprint "It seems that you are at fresh build environment.\nWe need to populate the config with some essential data.\nPlease answer the following questions or put your existing build config to configs/$PROJECTNAME-build.conf."
  PRINTOPTIONS=n statusprint "Proceed with interactive settings? [Y/n]: "
  read choice
  if [ ! -z "$choice" -a ! "$choice" == "y" -a ! "$choice" == "Y" ] 
  then
  echo "Build process aborted."
    exit 1
  else
    mkdir config 2>&-

    vpnhost=""
    while ! validate_vpnhostname "$vpnhost"
    do
      PRINTOPTIONS=n statusprint "Please enter your designated VPN server hostname/IP: "
      read vpnhost
      if ! validate_vpnhostname "$vpnhost"
      then
        statusprint "Invalid input data format. Please try again.."
      fi
    done

    vpnprotocol=""
    while ! validate_vpnprotocol "$vpnprotocol"
    do
      PRINTOPTIONS=n statusprint "Please enter your designated VPN server protocol (udp/tcp): "
      read vpnprotocol
      if ! validate_vpnprotocol "$vpnprotocol"
      then
        statusprint "Invalid input data format. Please try again.."
      fi
    done

    vpnport=""
    while ! validate_vpnport "$vpnport"
    do
      PRINTOPTIONS=n statusprint "Please enter your designated VPN server port: "
      read vpnport
      if ! validate_vpnport "$vpnport"
      then
        statusprint "Invalid input data format. Please try again.."
      fi
    done

    
    statusprint "Saving configuration.."
    echo "GLOBAL_VPNSERVER=\"$vpnhost\"
GLOBAL_VPNPROTOCOL=\"$vpnprotocol\"
GLOBAL_VPNPORT=\"$vpnport\"" > "$BUILDCONFPATH"
  fi
fi

exit 0;
