#!/bin/bash

if systemctl is-active --quiet openvpn ; then
    echo "OpenVPN is running."
else
    echo "OpenVPN is not running. Starting OpenVPN..."
    # Start OpenVPN service using systemctl
    # sudo systemctl start openvpn
    fi
