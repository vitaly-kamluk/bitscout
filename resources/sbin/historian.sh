#!/bin/bash
#Bitscout project
#Author: Vitaly Kamluk
#This script is used to store history of guest container's session input/output.
#It shall be started as a service. It saves history and timing information in gzip-files.

LOGDIR=/opt/container/history/log

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
  [ ! -p "$LOGDIR/host.pipe" ] && mkfifo "$LOGDIR/host.pipe" 2>&- && chmod o-r,o+w "$LOGDIR/host.pipe" 
  [ ! -f "$LOGDIR/host.lock" ] && touch "$LOGDIR/host.lock" 2>&- && chmod o+w "$LOGDIR/host.lock"

  while true;
  do
    echo "Waiting for the next session.."
    (
      flock 9
      mapfile -t PIPEMSG < <(cat "$LOGDIR/host.pipe"|head -n2)
      [ -f "/var/run/historian.stop" ] && exit 0;
      GUESTUSER=${PIPEMSG[0]}
      GUESTPID=${PIPEMSG[1]}
      if validate_user "$GUESTUSER" && validate_pid "$GUESTPID"
      then
        echo "Recording history for user:$GUESTUSER pid:$GUESTPID.."
        LOGF="$LOGDIR/${GUESTUSER}_${GUESTPID}"
        socat -u PIPE:"$LOGF.log.pipe" OPEN:"$LOGF.log",creat=1 &
        socat -u PIPE:"$LOGF.time.pipe" OPEN:"$LOGF.log.time",creat=1 &
        while [ ! -p "$LOGF.log.pipe" -a ! -p "$LOGF.time.pipe" ]; do sleep 0.1; done;
        chmod o+w,o-r "$LOGF.log.pipe" "$LOGF.time.pipe"
        flock -u 9
      fi
    ) 9> "$LOGDIR/host.lock"
  done
}

historian_stop()
{
  touch "/var/run/historian.stop"
  cat /dev/null > "$LOGDIR/host.pipe"
}


case $1 in
start) 
  historian_start
  ;;
stop)
  historian_stop
  ;;
esac
