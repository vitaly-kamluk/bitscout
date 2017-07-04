
#Initiates historian session from within monitored session
SESSPID=$$
SESSLOGDIR="/var/log/history"
(
flock 8
echo -e "$USER\n$SESSPID" > "$SESSLOGDIR/host.pipe"
(
 flock 9
 ) 9>"$SESSLOGDIR/host.lock"
) 8>"$HOME/.guest.lock"

if test -t 0
then
  script --timing="$SESSLOGDIR/${USER}_$SESSPID.time.pipe" -f -q "$SESSLOGDIR/${USER}_$SESSPID.log.pipe";
  exit
fi
