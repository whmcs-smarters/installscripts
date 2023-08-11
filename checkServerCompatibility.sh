#!/bin/bash
# check if it's root user
function isRoot () {
    if [ "$EUID" -ne 0 ]; then
        return 1
    fi
}
# tun/tap must be enabled
function tunAvailable () {
    if [ ! -e /dev/net/tun ]; then
        return 1
    fi
}
# checking operating system before the proceeding

function checkOS () {

 # if ! grep -qs "Ubuntu 18.04" /etc/os-release; then
 # echo "Installation Failed ! Your OS is not supported as it supports only Ubuntu 18.04 "
      #    exit
 # fi
}

function initialCheck () {
    if ! isRoot; then
        echo "Sorry, you need to run this as root"
        exit 1
    fi
    if ! tunAvailable; then
        echo "TUN is not available"
        exit 1
    fi
    checkOS
}
# Check for root, TUN, OS...
initialCheck
