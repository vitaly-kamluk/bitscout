#!/bin/bash
#Bitscout project
#Author: Vitaly Kamluk
#This script is used to store history of guest container's session input/output.
#It shall be started as a service. It saves history and timing information in gzip-files.

LOGDIR=/opt/container/history/log
IPCDIR=/opt/container/ipc

validate_user()
{
  echo "$1" | grep -q "[a-zA-Z0-9_-]\{1,32\}"; return $?;
}
validate_pid()
{
  echo "$1" | grep -q "[0-9]\{1,16\}"; return $?;
}


historian_start()
{
  [ ! -d "$IPCDIR" ] && mkdir -p "$IPCDIR"
  [ ! -p "$IPCDIR/historian.pipe" ] && mkfifo "$IPCDIR/historian.pipe" 2>&- && chmod o-r,o+w "$IPCDIR/historian.pipe" 
  [ ! -f "$IPCDIR/historian.lock" ] && touch "$IPCDIR/historian.lock" 2>&- && chmod o+w "$IPCDIR/historian.lock"

  while true;
  do
    echo "Waiting for the next session.."
    (
      flock 9
      mapfile -t PIPEMSG < <(cat "$IPCDIR/historian.pipe"|head -n2)
      [ -f "/var/run/historian.stop" ] && exit 0;
      GUESTUSER=${PIPEMSG[0]}
      GUESTPID=${PIPEMSG[1]}
      if validate_user "$GUESTUSER" && validate_pid "$GUESTPID"
      then
        echo "Recording history of user:$GUESTUSER pid:$GUESTPID.."
        PIPEFLOG="$IPCDIR/${GUESTUSER}_${GUESTPID}.log"
        PIPEFTIME="$IPCDIR/${GUESTUSER}_${GUESTPID}.time"
        FLOG="$LOGDIR/${GUESTUSER}_${GUESTPID}.log"
        FLOGTIME="$LOGDIR/${GUESTUSER}_${GUESTPID}.time"
        socat -u PIPE:"$PIPEFLOG" OPEN:"$FLOG",creat=1 &
        socat -u PIPE:"$PIPEFTIME" OPEN:"$FLOGTIME",creat=1 &
        while [ ! -p "$PIPEFLOG" -a ! -p "$PIPEFTIME" ]; do sleep 0.1; done;
        chmod o+w,o-r "$PIPEFLOG" "$PIPEFTIME"
        flock -u 9
      fi
    ) 9> "$IPCDIR/historian.lock"
    [ -f "/var/run/historian.stop" ] && exit 0;
  done
}

historian_stop()
{
  touch "/var/run/historian.stop"
  cat /dev/null > "$IPCDIR/historian.pipe"
}


case $1 in
start) 
  historian_start
  ;;
stop)
  historian_stop
  ;;
esac
