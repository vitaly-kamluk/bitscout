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
statusprint "Host OS info: $HOSTUNAME\n$HOSTDIST\nBuild Target:\t$PROJECTCAPNAME $PROJECTRELEASE\nUsing git commit:\t$COMMIT\n"

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

validate_vpntype()
{
  echo "$1" | grep -qE "^openvpn$|^wireguard$|^tor$"
  return $?
}

validate_vpnprotocol()
{
  echo "$1" | grep -qE "^udp$|^tcp$|^wireguard$|^tor$"
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

validate_target()
{
    case "$1" in
      "iso" | "raw" | "qcow2" | "vmdk") return 0;;
      *) return 1;
    esac
}

validate_ptabletype()
{
    case "$1" in
      "msdos" | "gpt" | "hybrid") return 0;;
      *) return 1;
    esac
}

validate_automount()
{
    case "$1" in
      "off" | "all") return 0;;
      *) return 1;
    esac
}

msg_new_config_opt="\nSome new options were not found in your config file, please answer the following question(s)\nand it will be appended to your existing config file located in config/$PROJECTNAME-build.conf.\n"

if ! [ -f "$BUILDCONFPATH" ]
then
  statusprint "Please answer some questions or place a build config in config/$PROJECTNAME-build.conf."
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
ptabletype=${GLOBAL_PARTITION_TABLE:-hybrid}
automount=${GLOBAL_AUTOMOUNT:-off}
buildarch="amd64"

if [ -z "$GLOBAL_RELEASESIZE" ]
then
    if  [ -f "$BUILDCONFPATH" ]; then PRINTOPTIONS=n statusprint "$msg_new_config_opt"; fi
    releasesize=""
    while ! validate_releasesize "$releasesize"
    do
      PRINTOPTIONS=n statusprint "\n${PROJECTNAME} builds vary in size.\nPlease choose one you prefer:\n 1. compact - minimal size, less tools and drivers.\n 2. normal - some forensic tools, all drivers, etc.\n 3. maximal - includes maximum forensic tools and frameworks.\nYour choice (1|2|3): "
      read releasesize
      if ! validate_releasesize "$releasesize"
      then
        releasesize=2
        statusprint "Auto-selected normal build size."
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

if [ -z "$GLOBAL_VPNTYPE" ]
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
        while ! validate_vpntype "$vpntype" && ! validate_hostaddr "$vpnhost" && ! validate_vpnprotocol "$vpnprotocol" && ! validate_portnum "$vpnport"
        do
          statusprint "\nTo use ${PROJECTNAME} over the internet you will likely need a VPN server."
          PRINTOPTIONS=n statusprint "Just enter your protocol/host/port and we generate a VPN config template for you. You can always change it later.\nExamples:\n openvpn-udp://127.0.0.1:1234\n openvpn-tcp://myvpnserver:8080\n wireguard://myvpnserver:2600\n tor\nYour input [connection string or <Enter> for none]: "
          read vpnuri
          [ "$vpnuri" == "tor" ] && vpntype="tor" && break;
          if [ ! -z "$vpnuri" ]
          then
            mapfile -t VPNCFG < <( echo "$vpnuri" | sed 's#^\(openvpn-udp\|openvpn-tcp\|wireguard\)://\([a-zA-Z0-9_.-]*\):\([0-9]\{1,5\}\)$#\2\n\1\n\3#' )
            vpntype=${VPNCFG[1]%%-*}
            vpnhost="${VPNCFG[0]}"
            vpnprotocol="${VPNCFG[1]##*-}"
            vpnport="${VPNCFG[2]}"

            if ! validate_vpntype "$vpntype" && ! validate_hostaddr "$vpnhost" && ! validate_vpnprotocol "$vpnprotocol" && ! validate_portnum "$vpnport"
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

sysloghost="none"

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

GLOBAL_BASEARCH=amd64

EXTRA_CONFIG=0
PRINTOPTIONS=n statusprint "Basic configuration complete. Build/Stop/Extra-config extra config? [B/s/e]: "
read choice

statusprint "\nSaving basic configuration.."
echo "GLOBAL_TARGET=\"$target\" #target to build: iso, raw, qcow2, vmdk
GLOBAL_PARTITION_TABLE=\"$ptabletype\" #partition table type: msdos,gpt,hybrid
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
GLOBAL_AUTOMOUNT=\"$automount\" #map and mount all available common filesystems: off or all 
CRYPTOKEYSIZE=$cryptokeysize" > "$BUILDCONFPATH"

if [ -z "$choice" -o "${choice^}" = "B" ]
then
    exit 0;
else
    if [ -z "$choice" -o "${choice^}" = "S" ]; then  exit 1; fi;
    if [ -z "$choice" -o "${choice^}" = "E" ]; then  EXTRA_CONFIG=1; fi;
fi


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

if [ $target != 'iso' ]; then
  ptabletype=""
  while ! validate_ptabletype "$ptabletype"
  do
    PRINTOPTIONS=n statusprint "\nChoose partition table type preference:\n msdos - used for MBR bootloaders (also used for the cloud instances).\n gpt - modern EFI systems\n hybrid - msdos+gpt on one disk, should be compatible with old and new systems\nYour choice [default=hybrid]: "
    read ptabletype
    if [ -z "$ptabletype" ]; then ptabletype="hybrid"; fi;
    if ! validate_ptabletype "$ptabletype"
    then
      statusprint "Invalid input. Please try again.."
      continue
    fi
  done
fi

automount=""
while ! validate_automount "$automount"
do
  PRINTOPTIONS=n statusprint "\n${PROJECTNAME} may automatically discover, map and readonly-mount disk partitions to the expert container. \nPlease choose your preference:\n off - disable automount\n all - enable automount of all disks\nYour choice [default=off]: "
  read automount
  if [ -z "$automount" ]; then automount="off"; fi;
  if ! validate_automount "$automount"
  then
    statusprint "Invalid input. Please try again.."
    continue
  fi
done

if [ -z "$GLOBAL_SYSLOGSERVER" ]
then
    if  [ -f "$BUILDCONFPATH" ]; then PRINTOPTIONS=n statusprint "$msg_new_config_opt"; fi
    sysloghost=""
    while ! validate_hostaddr "$sysloghost"
    do
        statusprint "\nA remote syslog server can keep your shell history. To continue without a syslog server simply press Enter."
        PRINTOPTIONS=n statusprint "Your input [syslog-host|<NONE>]: "
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

statusprint "\nUpdating basic configuration.."
echo "GLOBAL_TARGET=\"$target\" #target to build: iso, raw, qcow2, vmdk
GLOBAL_PARTITION_TABLE=\"$ptabletype\" #partition table type: msdos,gpt,hybrid
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
GLOBAL_AUTOMOUNT=\"$automount\" #map and mount all available common filesystems: off or all 
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
