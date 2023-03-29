#!/bin/bash
MEMTHRESHOLD_WARN=0.06 #relative value (0.0-1.0) of free RAM to send out a warning about low RAM
MEMTHRESHOLD_SUSP=0.03 #relative value (0.0-1.0) of free RAM to initiate the container suspension
INTERVAL=5 #seconds to sleep between memory status checks

#states:
# 1 - Running normally
# 2 - Issued a warning
# 3 - Suspended the container
free -s $INTERVAL -b | stdbuf -i0 -o0 -e0 awk 'BEGIN{ state=1; prev_state=state; threshold_warn='$MEMTHRESHOLD_WARN'; threshold_susp='$MEMTHRESHOLD_SUSP';} /^Mem:/ {if( $7/$2 <= threshold_warn && state==1 ){ state=2; printf "%0.2f%% %d\n",100*$7/$2,state;};  if( $7/$2 <= threshold_susp && state<=2 ){ state=3; printf "%0.2f%% %d\n",100*$7/$2,state;};  if($7/$2 >= threshold_susp && state==3){ if($7/$2 >= threshold_warn) {state=1} else {state=2}; printf "%0.2f%% %d\n",100*$7/$2, state; }}' |
 while IFS=$" " read p s;
 do
   echo "$p $s"
   case $s in
   1)
     logger "RAM Watchdog: $p of RAM is available. Resuming the container..";
     /usr/bin/container-resume.sh;
     ;;
   2)
     logger "RAM Watchdog: $p of RAM left. Issuing a global warning..";
     wall "RAM Watchdog warning: $p of RAM left";
     machinectl -q shell container /usr/bin/wall "RAM Watchdog warning: $p of RAM left. The container may be suspended soon." < /dev/null;
     ;;
   3)
     logger "RAM Watchdog: $p of RAM left. Suspending the container..";
     wall "RAM Watchdog warning: $p of RAM left";
     machinectl -q shell container /usr/bin/wall "RAM Watchdog warning: $p of RAM left. Suspending this container.." < /dev/null;
     /usr/bin/container-suspend.sh;
     ;;
   esac
 done