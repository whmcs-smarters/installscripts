#!/bin/bash
#create folders 
sudo mkdir -p /var/www/
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

# Define function to restart services
function restart_services {
  systemctl restart openvpn.service
  systemctl restart strongswan.service
}

# Check if services need to be restarted
if [[ "$(cat $OPENVPN_STATUS_FILE)" == "offline" || "$(cat $IKEV2_STATUS_FILE)" == "offline" ]]; then
  restart_services
  if [[ "$(cat $OPENVPN_STATUS_FILE)" == "online" && "$(cat $IKEV2_STATUS_FILE)" == "online" ]]; then
    echo "success"
  else
    echo "failed"
  fi
fi
