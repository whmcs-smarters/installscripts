#!/bin/bash
CPU=$(top -bn1 | grep load | awk '{printf "%.2f%%", $(NF-2)}')
echo -e '\E[32m'"CPU Load Average :" $CPU

# Memory usage % and total memory
MEMORY=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')
MEMORY_TOTAL=$(free -m | awk 'NR==2{printf "%s MB", $2}')
echo -e '\E[32m'"Memory usage :" $MEMORY
echo -e '\E[32m'"Total Memory :" $MEMORY_TOTAL

# Disk usage % and total disk size
DISK=$(df -h | awk '$NF=="/"{printf "%s", $5}')
DISK_TOTAL=$(df -h | awk '$NF=="/"{printf "%s", $2}')
echo -e '\E[32m'"Disk Usage :" $DISK
echo -e '\E[32m'"Total Disk :" $DISK_TOTAL

tecuptime=$(uptime | awk '{print $3,$4}' | cut -f1 -d,)
echo -e '\E[32m'"System Uptime Days/(HH:MM) :" $tecuptime

# Last update time
UPDATE_TIME=$(date +"%Y-%m-%d %H:%M:%S")
echo -e '\E[32m'"Last Update Time :" $UPDATE_TIME

# Define file paths for OpenVPN, IKEv2 and WireGuard status
OPENVPN_STATUS_FILE="/var/www/usage/openvpn.txt"
IKEV2_STATUS_FILE="/var/www/usage/ikev2.txt"
WIREGUARD_STATUS_FILE="/var/www/usage/wireguard.txt"

# Check if the OpenVPN service is running
if systemctl is-active openvpn@server > /dev/null 2>&1; then
  echo "online" > $OPENVPN_STATUS_FILE
  OPENVPN_STATUS="online"
else
  echo "offline" > $OPENVPN_STATUS_FILE
  OPENVPN_STATUS="offline"
fi
echo -e '\E[32m'"OpenVPN Status :" $OPENVPN_STATUS

# Check if the IKEv2 service is running
if ipsec status > /dev/null 2>&1; then
  echo "online" > $IKEV2_STATUS_FILE
  IKEV2_STATUS="online"
else
  echo "offline" > $IKEV2_STATUS_FILE
  IKEV2_STATUS="offline"
fi
echo -e '\E[32m'"IKEv2 Status :" $IKEV2_STATUS

# Check if the WireGuard service is running
if systemctl is-active wg-quick@wg0 > /dev/null 2>&1; then
  echo "online" > $WIREGUARD_STATUS_FILE
  WIREGUARD_STATUS="online"
else
  echo "offline" > $WIREGUARD_STATUS_FILE
  WIREGUARD_STATUS="offline"
fi
echo -e '\E[32m'"WireGuard Status :" $WIREGUARD_STATUS

echo "Calculating Bandwidth Usage"
eth0=$(ip route get 8.8.8.8 | awk -- '{printf $5}')
vnstat -tr -i $eth0 >> /tmp/usage.txt
upload=$(cat /tmp/usage.txt | grep -i "tx")
download=$(cat /tmp/usage.txt | grep -i "rx")
upload2=$(echo $upload | cut -d" " -f2,3)
download2=$(echo $download | cut -d" " -f2,3)
echo "Current upload data transfer speed :" $upload2
echo "Current download data transfer speed :" $download2
vnstat -t -s -i $eth0 >> /tmp/usage2.txt
totald=$(cat /tmp/usage2.txt | grep -i "today" | cut -f3 -d"/")
totald2=$(echo $totald | tr -d ' ')
echo  -e '\E[32m' "Total Data Usage:" $totald2
rm -Rf /tmp/usage*
cat > /var/www/usage/.htaccess <<EOF
<Files "index.html">
  Header set Content-Type "application/json"
</Files>
EOF
cat > /var/www/usage/index.html <<EOF
{
  "cpu": "$CPU",
  "memory_usage": "$MEMORY",
  "memory_total": "$MEMORY_TOTAL",
  "disk_usage": "$DISK",
  "disk_total": "$DISK_TOTAL",
  "uptime": "$tecuptime",
  "update_time": "$UPDATE_TIME",
  "openvpn_status": "$OPENVPN_STATUS",
  "ikev2_status": "$IKEV2_STATUS",
  "wireguard_status": "$WIREGUARD_STATUS",
  "network_upload": "$upload2",
  "network_download": "$download2",
  "total_data_usage": "$totald2"
}
EOF
