#!/bin/bash

# Define file paths for OpenVPN and IKEv2 status
if [ -e /var/www/status/openvpn.txt ]
then
   OPENVPN_STATUS_FILE="/var/www/status/openvpn.txt"
else
    mkdir -p /var/www/status/
    touch /var/www/status/openvpn.txt
    OPENVPN_STATUS_FILE="/var/www/status/openvpn.txt"
fi

if [ -e /var/www/status/ikev2.txt ]
then
  IKEV2_STATUS_FILE="/var/www/status/ikev2.txt"
else
    mkdir -p /var/www/status/
    touch /var/www/status/ikev2.txt
    IKEV2_STATUS_FILE="/var/www/status/ikev2.txt"
fi

# Check if the OpenVPN service is running
if systemctl is-active openvpn.service > /dev/null 2>&1; then
  echo "online" > $OPENVPN_STATUS_FILE
else
  echo "offline" > $OPENVPN_STATUS_FILE
fi

# Check if the IKEv2 service is running
if systemctl is-active strongswan.service > /dev/null 2>&1; then
  echo "online" > $IKEV2_STATUS_FILE
else
  echo "offline" > $IKEV2_STATUS_FILE
fi
