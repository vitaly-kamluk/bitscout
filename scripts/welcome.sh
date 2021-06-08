#!/bin/bash
#Bitscout project
#Copyright Kaspersky Lab

. ./scripts/functions

BUILDCONFPATH="config/${PROJECTNAME}-build.conf"
CONFIGNAME={"GLOBAL_RELEASESIZE"}

statusprint "Welcome to $PROJECTCAPNAME builder!"
HOSTUNAME=$(uname -srvi)
HOSTDIST=$(lsb_release -idrc 2>&-)
COMMIT=$(git log -1 2>&-|head -n1 | cut -d' ' -f2)
statusprint "Host OS info: $HOSTUNAME\n$HOSTDIST\nBuild Target:\t$PROJECTCAPNAME $PROJECTRELEASE\nGit commit:\t$COMMIT\n"

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
  statusprint "It seems that you are in a fresh build environment.\nWe need to populate the config with some essential data.\nPlease answer the following questions or put your existing build config to config/$PROJECTNAME-build.conf."
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
      PRINTOPTIONS=n statusprint "\n${PROJECTNAME} may be built in various sizes.\nPlease choose option number:\n 1. compact - minimal size, less tools and drivers.\n 2. normal - includes most common forensic tools, drivers, etc.\n 3. maximal - includes maximum forensic tools and frameworks.\n Your choice (1|2|3): "
      read releasesize
      if ! validate_releasesize "$releasesize"
      then
        statusprint "Invalid input data format. Please try again.."
      fi
    done
fi

#Override to default generic kernel:
GLOBAL_CUSTOMKERNEL=0
customkernel=0
if [ -z "$GLOBAL_CUSTOMKERNEL" ]
then
    if  [ -f "$BUILDCONFPATH" ]; then PRINTOPTIONS=n statusprint "$msg_new_config_opt"; fi
    customkernel="0"
    PRINTOPTIONS=n statusprint "\nIf you are going to deal with badly unmounted filesystems, software RAID or LVM, it is recommended to apply kernel write-blocker patch for extra care of the evidence. However, please note that this is experimental feature and may take 3-4 hours to rebuild the kernel on a single-core CPU.\nWould you like to build and use kernel with write-blocker? [y/N]: "
    read choice
    if [ -z "$choice" -o "${choice^}" = "N" ]
    then
      customkernel="0"
    else
      customkernel="1"
    fi

fi

if [ -z "$GLOBAL_VPNTYPE" -o "$GLOBAL_VPNTYPE" != 'none' ]
then 
  if [ -z "$GLOBAL_VPNSERVER" ] || [ -z "$GLOBAL_VPNPROTOCOL" ] || [ -z "$GLOBAL_VPNPORT" ]
  then
      if  [ -f "$BUILDCONFPATH" ]; then PRINTOPTIONS=n statusprint "$msg_new_config_opt"; fi
      vpntype=""
      vpnhost=""
      vpnprotocol=""
      vpnport=""
      if [ "$GLOBAL_VPNTYPE" != 'none' ]
      then
        while ! validate_hostaddr "$vpnhost" && ! validate_vpnprotocol "$vpnprotocol" && ! validate_portnum "$vpnport"
        do
          statusprint "\nTo use ${PROJECTNAME} over the internet you will likely need a VPN server."
          PRINTOPTIONS=n statusprint "Just enter your protocol/host/port and we generate an OpenVPN config template for you. You can always change it later.\nExamples:\n udp://127.0.0.1:2222\n tcp://myvpnserver:8080\nYour input [connection string|<NONE>]: "
          read vpnuri
          if [ ! -z "$vpnuri" ]
          then
            mapfile -t VPNCFG < <( echo "$vpnuri" | sed 's#^\(udp\|tcp\)://\([a-zA-Z0-9_.-]*\):\([0-9]\{1,5\}\)$#\2\n\1\n\3#' )
            vpntype="openvpn"
            vpnhost="${VPNCFG[0]}"
            vpnprotocol="${VPNCFG[1]}"
            vpnport="${VPNCFG[2]}"
    
            if ! validate_hostaddr "$vpnhost" && ! validate_vpnprotocol "$vpnprotocol" && ! validate_portnum "$vpnport"
            then
              statusprint "Invalid input data format. Please try again.."
            fi
          else
            vpntype="none"
            break;
          fi      
        done
      else
        vpntype="none"
        GLOBAL_VPNSERVER="none"
      fi
      if ( [ -n "$GLOBAL_VPNTYPE" -o -n "$GLOBAL_VPNSERVER" -o -n "$GLOBAL_VPNPROTOCOL" -o -n "$GLOBAL_VPNPORT" ] ) &&  [ -f "$BUILDCONFPATH" ]
      then
         echo "GLOBAL_VPNTYPE=\"$vpntype\"
GLOBAL_VPNSERVER=\"$vpnhost\"
GLOBAL_VPNPROTOCOL=\"$vpnprotocol\"
GLOBAL_VPNPORT=\"$vpnport\"" >> "$BUILDCONFPATH"
      fi
  fi
fi

if [ -z "$GLOBAL_SYSLOGSERVER" ]
then
    if  [ -f "$BUILDCONFPATH" ]; then PRINTOPTIONS=n statusprint "$msg_new_config_opt"; fi
    sysloghost=""
    while ! validate_hostaddr "$sysloghost"
    do
        statusprint "\nYou may configure a remote syslog server to log shell history. To continue without syslog server simply press Enter."
        PRINTOPTIONS=n statusprint "Your input [host|<NONE>]: "
        read sysloghost
        if [ "$sysloghost" = "" ]
        then
            sysloghost="none"
            statusprint "Remote syslog support disabled."
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
        PRINTOPTIONS=n statusprint "\nWhat's the target system architecture?\n1. 64-bit (amd64)\n2. 32-bit (i386)\nPlease choose [1|2]: "
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
    statusprint "\nSaving configuration.."
    echo "GLOBAL_RELEASESIZE=\"$releasesize\"
GLOBAL_HOSTSSH_ENABLED=0 #set to 1 to enable direct SSH access to the host system (port 23)
GLOBAL_LANACCESS_ENABLED=0 #set to 1 to enable access from LAN after boot
GLOBAL_VPNTYPE=\"$vpntype\"
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
