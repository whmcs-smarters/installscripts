#!/bin/sh
# Created by WHMCS-Smarters www.whmcssmarters.com
ipsec restart
# Don't modify package-provided service
cp /lib/systemd/system/openvpn\@.service /etc/systemd/system/openvpn\@.service

# Workaround to fix OpenVPN service on OpenVZ
sed -i 's|LimitNPROC|#LimitNPROC|' /etc/systemd/system/openvpn\@.service
# Another workaround to keep using /etc/openvpn/
sed -i 's|/etc/openvpn/server|/etc/openvpn|' /etc/systemd/system/openvpn\@.service

systemctl daemon-reload
systemctl restart openvpn@server
systemctl enable openvpn@server
