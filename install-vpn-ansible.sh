#!/bin/bash
#Created by WHMCS-Smarters Team. We provide VPN Software Solution & Services for Business at www.whmcssmarters.com
sudo apt-get update -yq
sudo apt-add-repository ppa:ansible/ansible -yq
sudo apt-get install ansible -y
apt-get install git -y
git clone https://amansmarters:aa29246e0d9acd108307e63fd8bf5e6b0cfe957b@github.com/whmcs-smarters/whmcssmarters.git
cd whmcssmarters/ansible/
ansible-playbook    a
