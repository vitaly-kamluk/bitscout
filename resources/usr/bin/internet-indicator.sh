#!/bin/bash


function startIndicator() {
    while [ 1 ]
    do
        if nc -zw1 google.com 443 2>/dev/null; then
            sudo sed -i 's/screen_color = (CYAN,RED,ON)/screen_color = (CYAN,BLUE,ON)/g' /etc/dialogrc # Internet Connection Exist
        else
            sudo sed -i 's/screen_color = (CYAN,BLUE,ON)/screen_color = (CYAN,RED,ON)/g' /etc/dialogrc # Internet Connection Dosen't exist
        fi
    done
}

function stopIndicator() {
    sudo sed -i 's/screen_color = (CYAN,RED,ON)/screen_color = (CYAN,BLUE,ON)/g' /etc/dialogrc # Internet Connection Exist
    a=$(ps -ef | grep -v grep | grep <script_name> | awk '{print $2}')
    kill -9 $a
    #sudo sed -i 's/screen_color = (CYAN,RED,ON)/screen_color = (CYAN,BLUE,ON)/g' /etc/dialogrc # Internet Connection Exist
}

case "$1" in
    start)
        startIndicator
        ;;

    stop)
        stopIndicator
        ;;
esac
