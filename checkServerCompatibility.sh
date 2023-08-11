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

function initialCheck () {
    if ! isRoot; then
        echo "Sorry, you need to run this as root"
        exit 1
    fi
    if ! tunAvailable; then
        echo "TUN is not available"
        exit 1
    fi
}
# Check for root, TUN, OS...
initialCheck
