#!/bin/bash
CONTAINERROOT=/opt/container/chroot
CONTROLFILE=/var/run/privexec.enabled
IPCDIR=/opt/container/ipc
PRIVPIPE="$IPCDIR/privexec.pipe"
PRIVLOCK="$IPCDIR/privexec.lock"
PRIVLOGDIR=/opt/container/history/log
PRIVLOG="$PRIVLOGDIR/privexecd.log"

CMD_WHITELIST=( "/usr/bin/mount" "/usr/bin/umount" )
FS_WHITELIST=( "ntfs" "ntfs-3g" "vfat" "exfat" "ext" "ext2" "ext3" "ext4" "iso9660" "udf" "xfs" "reiserfs" "hfs" "hfsplus"  )
declare -a LINE

RESPONSEMSG=""
response_add()
{
  RESPONSEMSG="$RESPONSEMSG$1"
}

response_push()
{
  if [ -n "$RESPONSEMSG" ]
  then
    echo -e "$RESPONSEMSG" > "$PRIVPIPE"
    RESPONSEMSG=""
  fi
}


log_add()
{
  T=$(TZ=UTC date +"%H:%M:%S %Y-%m-%d")
  echo "$T: $1" >> "$PRIVLOG"
  echo "$T: $1"
}

privileged_usr_bin_mount()
{
  log_add "privileged_bin_mount ${LINE[*]}"
  ARGLEN=${LINE[0]}
  if [ $ARGLEN -lt 2 -o $ARGLEN -gt 6 ]
  then
   log_add "Invalid number of arguments: $ARGLEN"
   return 1;
  fi

  FSTYPE="auto"
  MOUNTOPT="nodev,nosuid,noatime"
  for((i=2;i<$ARGLEN;i++))
  do
   if [ "${LINE[$i]}" == "-t" ]; then FSTYPE=${LINE[$i+1]}; fi
   if [ "${LINE[$i]}" == "-o" ]; then MOUNTOPT="$MOUNTOPT,"${LINE[$i+1]}; fi
  done

  if ! is_fs_authorized "$FSTYPE"; 
  then 
    log_add "Prohibited filesystem $FSTYPE"; 
    response_add "Cannot mount filesystem $FSTYPE.\n"
    return 1; 
  fi;

  SRC="/opt/container/chroot${LINE[$ARGLEN]}"
  DST="/opt/container/chroot${LINE[$ARGLEN+1]}"
  if is_valid_path "$SRC" && is_valid_path "$DST" && is_valid_option "$MOUNTOPT" && is_valid_option "$FSTYPE"
  then
    log_add "Running: mount -t \"$FSTYPE\" -o \"$MOUNTOPT\" --source \"$SRC\" --target \"$DST\" 2>&1"
    mount -v -t "$FSTYPE" -o "$MOUNTOPT" --source "$SRC" --target "$DST" 2>&1 >"$PRIVPIPE"
    return 0;
  else
    return 1;
  fi
}

privileged_usr_bin_umount()
{
  SRC="/opt/container/chroot${LINE[2]}"
  if is_valid_path "$SRC"
  then
    log_add "Running: umount \"${SRC}\" 2>&1"
    umount "${SRC}" 2>&1 >"$PRIVPIPE"
    return 0
  else
    return 1
  fi
}

is_fs_authorized()
{
  for allowed in "${FS_WHITELIST[@]}"; do [[ "$1" == "$allowed" ]] && return 0; done; return 1;
}

is_cmd_authorized()
{
  for allowed in "${CMD_WHITELIST[@]}"; do [[ "$1" == "$allowed" ]] && return 0; done; return 1;
}

is_valid_path()
{
 if echo "$1" | grep -q "^[/a-zA-Z0-9_. ()=+-]\{2,256\}$"
 then
  RP=`realpath "$1"`
  echo $RP | grep -q "^/opt/container/chroot/" && return 0
 fi
 log_add "Path validation failed: $1"
 return 1
}

is_valid_option()
{
 echo "$1" | grep -q "^[\/\\a-zA-Z0-9_. ()=+,:;-]\{1,256\}$" && return 0
 log_add "Params validation failed: $1"
 return 1
}

[ ! -d "$IPCDIR" ] && mkdir -p "$IPCDIR";
[ ! -d "$PRIVLOGDIR" ] && mkdir -p "$PRIVLOGDIR";
[ ! -p "$PRIVPIPE" ] && mkfifo "$PRIVPIPE" && chmod o+rw "$PRIVPIPE";
[ ! -p "$PRIVLOCK" ] && touch "$PRIVLOCK" && chmod o+rw "$PRIVLOCK";

while true
do
  response_push
  mapfile -t LINE < <(head -n1 "$PRIVPIPE" | awk -vFPAT='([^ ]*)|("[^"]+")' -vOFS=" " '{for(i=1;i<=NF;i++){print $i;}}'| sed 's/^"//; s/"$//' )
  if [ ! -f "$CONTROLFILE" ]
  then
    response_add "Privileged execution mode is not enabled.\n"
    CMDREQ=$(echo "${LINE[*]}" | sed 's/^[0-9]\{1,2\} //')
    log_add "Guest container requested privileged mode command but was denied: $CMDREQ"
    continue
  fi

  CMDPATH=${LINE[1]}; CMDPATH=${CMDPATH%%.priv}
  if is_cmd_authorized "$CMDPATH"
  then
    log_add "Request to run privileged $CMDPATH"
    PROCNAME=${CMDPATH////_}
    if ! eval "privileged$PROCNAME"
    then 
      log_add "Failed to run privileged$PROCNAME"
      response_add "Failed to run privileged command.\n Hints:\n  1. Use \"-o ro\" option when mounting\n  2. Specify filesystem type with -t <type>\n  3. Make sure src and dest paths exist\n"
    fi
  else
    log_add "Denied running $CMDPATH"
    echo "Couldn't process your request due to input validation." > "$PRIVPIPE"
  fi
  #declare -p LINE
done

