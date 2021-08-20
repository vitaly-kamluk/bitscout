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

validate_target()
{
    case "$1" in
      "iso" | "raw" | "qcow2" | "vmdk") return 0;;
      *) return 1;
    esac
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
else
  . "$BUILDCONFPATH"
fi

target=${GLOBAL_TARGET:-iso}
persistsize=${GLOBAL_PERSISTSIZE:-1GiB}
lanaccess=${GLOBAL_LANACCESS_ENABLED:-0}
hostssh=${GLOBAL_HOSTSSH_ENABLED:-0}

if [ -z "$GLOBAL_RELEASESIZE" ]
then
    if  [ -f "$BUILDCONFPATH" ]; then PRINTOPTIONS=n statusprint "$msg_new_config_opt"; fi
    releasesize=""
    while ! validate_releasesize "$releasesize"
    do
      PRINTOPTIONS=n statusprint "\n${PROJECTNAME} may be built in various sizes.\nPlease choose option number:\n 1. compact - minimal size, less tools and drivers.\n 2. normal - includes most common forensic tools, drivers, etc.\n 3. maximal - includes maximum forensic tools and frameworks.\nYour choice (1|2|3): "
      read releasesize
      if ! validate_releasesize "$releasesize"
      then
        statusprint "Invalid input data format. Please try again.."
      fi
    done
else
  releasesize=$GLOBAL_RELEASESIZE
fi

#Override to default generic kernel:
GLOBAL_CUSTOMKERNEL=0
customkernel=0
if [ -z "$GLOBAL_CUSTOMKERNEL" ]
then
    if  [ -f "$BUILDCONFPATH" ]; then PRINTOPTIONS=n statusprint "$msg_new_config_opt"; fi
    customkernel="0"
    PRINTOPTIONS=n statusprint "\nWould you like to build Linux kernel from source (may take hours)? [y/N]: "
    read choice
    if [ -z "$choice" -o "${choice^}" = "N" ]
    then
      customkernel="0"
    else
      customkernel="1"
    fi
else
  customkernel=$GLOBAL_CUSTOMKERNEL
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
  fi
else
  vpntype=$GLOBAL_VPNTYPE
  vpnhost=$GLOBAL_VPNSERVER
  vpnprotocol=$GLOBAL_VPNPROTOCOL
  vpnport=$GLOBAL_VPNPORT
fi

if [ -z "$GLOBAL_SYSLOGSERVER" ]
then
    if  [ -f "$BUILDCONFPATH" ]; then PRINTOPTIONS=n statusprint "$msg_new_config_opt"; fi
    sysloghost=""
    while ! validate_hostaddr "$sysloghost"
    do
        statusprint "\nYou may configure a remote syslog server to log shell history. To continue without a syslog server simply press Enter."
        PRINTOPTIONS=n statusprint "Your input [host|<NONE>]: "
        read sysloghost
        if [ "$sysloghost" = "" ]
        then
            sysloghost="none"
            statusprint "Remote syslog support disabled."
            break
        fi
        if ! validate_hostaddr "$sysloghost"
        then
            statusprint "Invalid input data format. Please try again.."
        fi
    done
else
  sysloghost=$GLOBAL_SYSLOGSERVER
fi

if [ -z "$GLOBAL_BUILDID" ]
then    
    if  [ -f "$BUILDCONFPATH" ]; then PRINTOPTIONS=n statusprint "$msg_new_config_opt"; fi
    buildid=`dd if=/dev/urandom bs=1 count=4 2>&- | xxd -pos`
    if [ -n "$GLOBAL_BUILDID" ] &&  [ -f "$BUILDCONFPATH" ]; then
        echo "GLOBAL_BUILDID=\"$buildid\"" >> "$BUILDCONFPATH"
    fi
else
  buildid=$GLOBAL_BUILDID
fi

if [ -z "$CRYPTOKEYSIZE" ]
then
  cryptokeysize=2048
else
  cryptokeysize=$CRYPTOKEYSIZE
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
else
  buildarch=$GLOBAL_BASEARCH
fi

EXTRA_CONFIG=0
PRINTOPTIONS=n statusprint "Basic configuration complete. Build/Stop/Extra-config extra config? [B/s/e]: "
read choice

statusprint "\nSaving basic configuration.."
echo "GLOBAL_TARGET=\"$target\" #target to build: iso, raw, qcow2, vmdk
GLOBAL_PERSISTSIZE=\"$persistsize\" #persistence partition size for non-iso builds
GLOBAL_RELEASESIZE=\"$releasesize\"
GLOBAL_HOSTSSH_ENABLED=$hostssh #set to 1 to enable direct SSH access to the host system (port 23)
GLOBAL_LANACCESS_ENABLED=$lanaccess #set to 1 to enable access from LAN after boot
GLOBAL_VPNTYPE=\"$vpntype\"
GLOBAL_VPNSERVER=\"$vpnhost\"
GLOBAL_VPNPROTOCOL=\"$vpnprotocol\"
GLOBAL_VPNPORT=\"$vpnport\"
GLOBAL_SYSLOGSERVER=\"$sysloghost\"
GLOBAL_BUILDID=\"$buildid\"
GLOBAL_CUSTOMKERNEL=\"$customkernel\" 
GLOBAL_BASEARCH=\"$buildarch\" #amd64 (64bit) or i386 (32-bit)
CRYPTOKEYSIZE=$cryptokeysize" > "$BUILDCONFPATH"

if [ -z "$choice" -o "${choice^}" = "B" ]
then
    exit 0;
else
    if [ -z "$choice" -o "${choice^}" = "S" ]; then  exit 1; fi;
    if [ -z "$choice" -o "${choice^}" = "E" ]; then  EXTRA_CONFIG=1; fi;
fi


if [ $EXTRA_CONFIG -eq 1 ]; then
  target=""
  while ! validate_target "$target"
  do
    PRINTOPTIONS=n statusprint "\n${PROJECTNAME} may build different targets.\nPlease choose your preference:\n iso - bootable LiveCD ISO image.\n raw - raw disk image with preinstalled system\n qcow2 - qemu/libvirt disk image with preinstalled system\n vmdk - VMware Workstation or VirtualBox disk image with preinstalled system\nYour choice [default=iso]: "
    read target
    if [ -z "$target" ]; then target="iso"; fi;
    if ! validate_target "$target"
    then
      statusprint "Invalid input. Please try again.."
      continue
    fi
  done
fi

statusprint "\nUpdating basic configuration.."
echo "GLOBAL_TARGET=\"$target\" #target to build: iso, raw, qcow2, vmdk
GLOBAL_PERSISTSIZE=\"$persistsize\" #persistence partition size for non-iso builds
GLOBAL_RELEASESIZE=\"$releasesize\"
GLOBAL_HOSTSSH_ENABLED=$hostssh #set to 1 to enable direct SSH access to the host system (port 23)
GLOBAL_LANACCESS_ENABLED=$lanaccess #set to 1 to enable access from LAN after boot
GLOBAL_VPNTYPE=\"$vpntype\"
GLOBAL_VPNSERVER=\"$vpnhost\"
GLOBAL_VPNPROTOCOL=\"$vpnprotocol\"
GLOBAL_VPNPORT=\"$vpnport\"
GLOBAL_SYSLOGSERVER=\"$sysloghost\"
GLOBAL_BUILDID=\"$buildid\"
GLOBAL_CUSTOMKERNEL=\"$customkernel\" 
GLOBAL_BASEARCH=\"$buildarch\" #amd64 (64bit) or i386 (32-bit)
CRYPTOKEYSIZE=$cryptokeysize" > "$BUILDCONFPATH"

EXTRA_CONFIG=0
PRINTOPTIONS=n statusprint "New configuration saved. Proceed to the building phase? [Y/n]: "
read choice
if [ -z "$choice" -o "${choice^}" = "Y" ]
then
  exit 0;
else
  exit 1;
fi

exit 0;
