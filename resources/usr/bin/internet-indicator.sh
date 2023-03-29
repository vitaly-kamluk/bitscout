#!/bin/bash
CONNCHECK_HOST="bitscout-forensics.info"

function run_test() {
    ping -n -c1 ${CONNCHECK_HOST}
    status=$?
    if [ $status -eq 0 ]; then
        [ ! -f /run/internet_on.status -a ! -f /run/internet_off.status ] && touch /run/internet_on.status
        [ -f /run/internet_off.status ] && rm /run/internet_off.status
    else
        [ ! -f /run/internet_on.status -a ! -f /run/internet_off.status ] && touch /run/internet_off.status
        [ -f /run/internet_on.status ] && rm /run/internet_on.status
    fi
    return 0
}

function clean() {
    rm /run/internet_{on,off}.status 2>/dev/null
    return 0
}

case "$1" in
    start)
        run_test
        ;;

    stop)
        clean
        ;;
esac
