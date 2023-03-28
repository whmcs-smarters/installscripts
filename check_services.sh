#!/bin/bash

# Define file paths for OpenVPN and IKEv2 status
OPENVPN_STATUS_FILE="/var/www/status/openvpn.txt"
IKEV2_STATUS_FILE="/var/www/status/ikev2.txt"

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
