#!/bin/bash
# check if it's root user

while getopts ":p:" o
do
    case "${o}" in
    p) DIRPATH=${OPTARG}
    ;;
        esac
    done
function isRoot () {
    if [ "$EUID" -ne 0 ]; then
        return 1
    fi
}
 
# checking operating system before the proceeding

function checkOS () {
  if ! grep -qs "Ubuntu 18.04" /etc/os-release; then
  echo "Installation Failed ! Your OS is not supported as it supports only Ubuntu 18.04 "
          exit
  fi
}
function PanelCheck(){
FILE="$DIRPATH"/configuration.php
if [ -e "$FILE" ] ;then
echo "installed"
exit 1
}
function initialCheck () {
    if ! isRoot; then
        echo "Sorry, you need to run this as root"
        exit 1
    fi
    checkOS
}
# Check for root, TUN, OS...
initialCheck
PanelCheck
