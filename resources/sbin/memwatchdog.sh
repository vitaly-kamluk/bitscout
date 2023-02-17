#!/bin/bash
MEMTHRESHOLD_WARN=0.06 #relative value (0.0-1.0) of free RAM to send out a warning about low RAM
MEMTHRESHOLD_SUSP_CONTAINER_PROCESS=0.03 #relative value (0.0-1.0) of free RAM to initiate the container suspension
MEMTHRESHOLD_SUSP_CONTAINER_MACHINE=0.02 #relative value (0.0-1.0) of free RAM to initiate the container suspension
INTERVAL=5 #seconds to sleep between memory status checks

#states:
# 1 - Running normally
# 2 - Issued a warning
# 3 - Suspend the container major process
# 4 - Suspended the container machine
free -s $INTERVAL -b | stdbuf -i0 -o0 -e0 awk 'BEGIN{ state=1; prev_state=state; threshold_warn='$MEMTHRESHOLD_WARN';threshold_susp_container_process='$MEMTHRESHOLD_SUSP_CONTAINER_PROCESS';threshold_susp_container_machine='$MEMTHRESHOLD_SUSP_CONTAINER_MACHINE';} /^Mem:/ {if( $7/$2 <= threshold_warn && state==1 ){state=2; printf "%0.2f%% %d\n",100*$7/$2,state;}; if( $7/$2 <= threshold_susp_container_process && state<=2 ){state=3; printf "%0.2f%% %d\n",100*$7/$2,state;}; if( $7/$2 <= threshold_susp_container_machine && state<=3 ){state=4; printf "%0.2f%% %d\n",100*$7/$2,state;};if($7/$2 >= threshold_susp_container_machine && state==4){if($7/$2 >= threshold_warn){state=1} if($7/$2 >= threshold_susp_container_process){state=2}; printf "%0.2f%% %d\n",100*$7/$2, state;}}' |
 
 while IFS=$" " read p s;
 do
   echo "$p $s"
   case $s in
   1)
     logger "RAM Watchdog: $p of RAM is available. Resuming the container..";
     /usr/bin/container-resume.sh;
     sudo [ ! -e /run/tmpContainerProcessStatus ] && sudo touch /run/tmpContainerProcessStatus
     systemd-run --machine container sudo [ ! -e /run/tmpKill ] && sudo touch /run/tmpKill && sudo echo "$(ps aux --sort=-%mem | awk '$1 == "user" {print $2}' | head -n 1)" > /run/tmpKill && sudo kill -CONT "$(sudo cat /run/tmpKill)" 
     sudo echo "0" > /run/tmpContainerProcessStatus
     ;;
   2)
     logger "RAM Watchdog: $p of RAM left. Issuing a global warning..";
     wall "RAM Watchdog warning: $p of RAM left";
     machinectl -q shell container /usr/bin/wall "RAM Watchdog warning: $p of RAM left. The container may be suspended soon." < /dev/null;
     sudo [ ! -e /run/tmpContainerProcessStatus ] && sudo touch /run/tmpContainerProcessStatus
     systemd-run --machine container sudo [ ! -e /run/tmpKill ] && sudo touch /run/tmpKill && sudo echo "$(ps aux --sort=-%mem | awk '$1 == "user" {print $2}' | head -n 1)" > /run/tmpKill && sudo kill -CONT "$(sudo cat /run/tmpKill)" 
     sudo echo "0" > /run/tmpContainerProcessStatus
     ;;
   3)
     logger "RAM Watchdog: $p of RAM left. Suspending the container major process..";
     wall "RAM Watchdog warning: $p of RAM left";
     machinectl -q shell container /usr/bin/wall "RAM Watchdog warning: $p of RAM left. Suspending this container major process.." < /dev/null;
     sudo [ ! -e /run/tmpContainerProcessStatus ] && sudo touch /run/tmpContainerProcessStatus
     systemd-run --machine container sudo [ ! -e /run/tmpKill ] && sudo touch /run/tmpKill && sudo echo "$(ps aux --sort=-%mem | awk '$1 == "user" {print $2}' | head -n 1)" > /run/tmpKill && sudo kill -STOP "$(sudo cat /run/tmpKill)" 
     sudo echo "1" > /run/tmpContainerProcessStatus
     ;;
   4)
     logger "RAM Watchdog: $p of RAM left. Suspending the container..";
     wall "RAM Watchdog warning: $p of RAM left";
     machinectl -q shell container /usr/bin/wall "RAM Watchdog warning: $p of RAM left. Suspending this container.." < /dev/null;
     /usr/bin/container-suspend.sh;
     ;;
   esac
 done