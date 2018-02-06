
#Initiates historian session from within monitored session
SESSPID=$$
IPCDIR="/var/host/ipc"
(
flock 8
echo -e "$USER\n$SESSPID" > "$IPCDIR/historian.pipe"
(
 flock 9
 ) 9>"$IPCDIR/historian.lock"
) 8>"$HOME/.guest.lock"

if test -t 0
then
  script --timing="$IPCDIR/${USER}_$SESSPID.time" -f -q "$IPCDIR/${USER}_$SESSPID.log";
  exit
fi
