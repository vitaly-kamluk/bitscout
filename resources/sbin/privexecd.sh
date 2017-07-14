#!/bin/bash
CONTAINERNAME=forensic
CONTAINERUSER=user
CONTAINERROOT=/opt/container/chroot
IPCDIR=/opt/container/ipc
PRIVPIPE="$IPCDIR/privexec.pipe"
PRIVLOCK="$IPCDIR/privexec.lock"
PRIVLOG=/opt/container/history/log/privexecd.log

CMD_WHITELIST=( "/bin/mount" "/bin/umount" )
FS_WHITELIST=( "ntfs" "ntfs-3g" "vfat" "exfat" "ext" "ext2" "ext3" "ext4" "iso9660" "udf" "xfs" "resiserfs" "hfs" "hfsplus"  )
declare -a LINE

log_add()
{
  T=$(TZ=UTC date +"%H:%M:%S %Y-%m-%d %Z")
  echo "$T: $1" >> "$PRIVLOG"
  echo "$T: $1"
}

privileged_bin_mount()
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
    echo "Cannot mount filesystem $FSTYPE." > "$PRIVPIPE"
    return 1; 
  fi;

  SRC=${LINE[$ARGLEN]}
  DST=${LINE[$ARGLEN+1]}
  log_add "Running: chroot \"/opt/container/chroot\" mount -t \"$FSTYPE\" -o \"$MOUNTOPT\" --source \"$SRC\" --target \"$DST\" 2>&1"
  chroot "/opt/container/chroot" mount -v -t "$FSTYPE" -o "$MOUNTOPT" --source "$SRC" --target "$DST" 2>&1 >"$PRIVPIPE"
  return 0;
}

privileged_bin_umount()
{
  chroot "/opt/container/chroot" umount "${LINE[2]}" 2>&1 >"$PRIVPIPE"
}

is_fs_authorized()
{
  for allowed in "${FS_WHITELIST[@]}"; do [[ "$1" == "$allowed" ]] && return 0; done; return 1;
}

is_cmd_authorized()
{
  for allowed in "${CMD_WHITELIST[@]}"; do [[ "$1" == "$allowed" ]] && return 0; done; return 1;
}

[ ! -p "$PRIVPIPE" ] && mkfifo "$PRIVPIPE" && chmod o+rw "$PRIVPIPE";
[ ! -p "$PRIVLOCK" ] && touch "$PRIVLOCK" && chmod o+rw "$PRIVLOCK";

while true
do
  mapfile -t LINE < <(head -n1 "$PRIVPIPE" | awk -vFPAT='([^ ]*)|("[^"]+")' -vOFS=" " '{for(i=1;i<=NF;i++){print $i;}}'| sed 's/^"//; s/"$//' )
  CMDPATH=${LINE[1]}; CMDPATH=${CMDPATH%%.priv}
  if is_cmd_authorized "$CMDPATH"
  then
    log_add "Request to run privileged $CMDPATH"
    PROCNAME=${CMDPATH////_}
    if ! eval "privileged$PROCNAME"; then log_add "Failed to run privileged$PROCNAME"; fi;
  else
    log_add "Denied running $CMDPATH"
  fi
  #declare -p LINE
done
