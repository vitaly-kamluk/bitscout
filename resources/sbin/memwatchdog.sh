#!/bin/bash
MEMTHRESHOLD=0.1 #relative value (0.0-1.0) of free RAM to initiate the container suspension
INTERVAL=5 #seconds to sleep between memory status checks

free -s $INTERVAL -b | stdbuf -i0 -o0 -e0 awk 'BEGIN{suspended=0; threshold='$MEMTHRESHOLD'} /^Mem:/ {if( $7/$2 <= threshold && suspended==0 ){ printf "%0.2f%% %d\n",$7/$2,suspended; suspended=1}; if($7/$2 > threshold && suspended==1){ printf "%0.2f%% %d\n",$7/$2, suspended; suspended=0 }}' | 
 while IFS=$" " read p s; 
 do 
   if [ $s -eq 0 ]
   then 
     logger "RAM Watchdog: $p of RAM left. Suspending the container..";
     /usr/bin/container-suspend.sh;
   else 
     logger "RAM Watchdog: $p of RAM is available. Resuming the container.."; 
     /usr/bin/container-resume.sh; 
   fi; 
 done

