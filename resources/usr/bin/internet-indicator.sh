#!/bin/bash

function startIndicator() {
    ping -c1 bitscout-forensics.info
    status=$?
    if [ $status == 0 ] ; then
        [[ ! -f /run/internetOn.status && ! -f /run/internetOff.status ]] && touch /run/internetOn.status
        [ -f /run/internetOff.status ] && mv /run/internetOff.status /run/internetOn.status
        return 0;
    else
        [[ ! -f /run/internetOn.status && ! -f /run/internetOff.status ]] && touch /run/internetOff.status
        [ -f /run/internetOn.status ] && mv /run/internetOn.status /run/internetOff.status
        return 0;
    fi

}

function stopIndicator() {
    [ -f /run/internetOn.status ] && rm /run/internetOn.status && return 0;
    [ -f /run/internetOff.status ] && rm /run/internetOff.status && return 0;
}

case "$1" in
    start)
        startIndicator
        ;;

    stop)
        stopIndicator
        ;;
esac