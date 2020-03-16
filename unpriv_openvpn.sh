#!/bin/bash
#
# 
# GET CURRENT USER NAME | GROUP
export PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PATH
USERNAME=$(id -u -n)
GROUP=$(id -Gn)
OVPN_DIR=$(pwd)
OVPN_CNF=$conf_file
OVPN_BIN=$(which openvpn)
function whitelist_ovpn(){
echo "$USERNAME ALL = NOPASSWD:$OVPN_BIN --config $OVPN_DIR/$OVPN_CNF" >> /etc/sudoers
echo "$USERNAME ALL = NOPASSWD:$OVPN_BIN --config $OVPN_DIR/$OVPN_CNF" >> /etc/sudoers
}
# The above add the corresponding lines to /etc/sudoers
# Then inside the app, call openvpn using sudo (it should not prompt the user for a password)
# sudo openvpn --config $OVPN_DIR/$OVPN_CNF

