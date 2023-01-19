#!/bin/bash

function startIndicator() {
    while [ 1 ]
    do
        ping -c1 bitscout-forensics.info
        status=$?
        if [ $status == 0 ] ; then
            sudo sed -i 's/screen_color = (CYAN,RED,ON)/screen_color = (CYAN,BLUE,ON)/g' /etc/internet.dialogrc

        else
            sudo sed -i 's/screen_color = (CYAN,BLUE,ON)/screen_color = (CYAN,RED,ON)/g' /etc/internet.dialogrc
        fi
    done
}

function stopIndicator() {
    sudo sed -i 's/screen_color = (CYAN,RED,ON)/screen_color = (CYAN,BLUE,ON)/g' /etc/internet.dialogrc
}

case "$1" in
    start)
        startIndicator
        ;;

    stop)
        stopIndicator
        ;;
esac