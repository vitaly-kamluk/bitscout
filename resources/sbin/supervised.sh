#!/bin/bash
CONTAINERROOT=/opt/container/chroot
SUPERVISEDROOT=/var/run/supervised
IPCDIR=/opt/container/ipc
COMMPIPE_IN="$IPCDIR/supervised_in.pipe"
COMMPIPE_OUT="$IPCDIR/supervised_out.pipe"
COMMLOCK="$IPCDIR/supervised.lock"
SUPERVISEDBYPASS="$SUPERVISEDROOT/bypass"
SUPERVISEDAUTHPIPE="$SUPERVISEDROOT/auth.pipe"
COMMLOGDIR=/opt/container/history/log
COMMLOG=$COMMLOGDIR/supervised.log

log_add()
{
  T=$(TZ=UTC date +"%H:%M:%S %Y-%m-%d")
  echo "$T: $1" >> "$COMMLOG"
  echo "$T: $1"
}

[ ! -d "$COMMLOGDIR" ] && mkdir -p "$COMMLOGDIR";
[ ! -d "$SUPERVISEDROOT" ] && mkdir -p "$SUPERVISEDROOT";
[ ! -d "$IPCDIR" ] && mkdir -p "$IPCDIR";
[ ! -p "$COMMPIPE_IN" ] && mkfifo "$COMMPIPE_IN" && chmod o+rw "$COMMPIPE_IN";
[ ! -p "$COMMPIPE_OUT" ] && mkfifo "$COMMPIPE_OUT" && chmod o+rw "$COMMPIPE_OUT";
[ ! -p "$COMMLOCK" ] && touch "$COMMLOCK" && chmod o+rw "$COMMLOCK";
[ ! -p "$SUPERVISEDAUTHPIPE" ] && mkfifo "$SUPERVISEDAUTHPIPE";

while true
do
  CMD=`head -n1 $COMMPIPE_IN`
  log_add "Supervised command received: $CMD"
  if [ -f "$SUPERVISEDBYPASS" ]
  then
    eval "$CMD 2>&1" 1>$COMMPIPE_OUT
  else
    (
     echo "Your command is being reviewed. Once review is complete, you shall see output here."
     echo "$CMD" > $SUPERVISEDAUTHPIPE
     RESULT=`head -n1 $SUPERVISEDAUTHPIPE`
     if [ "$RESULT" = "0" ]
     then #true
       eval "$CMD 2>&1" | tee -a "$COMMLOG" > $COMMPIPE_OUT
     else #false
       echo "Last command was not approved. Please talk to the owner."
     fi
    ) > "$COMMPIPE_OUT"
  fi
  done
