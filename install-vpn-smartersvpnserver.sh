#!/bin/bash

###########################################################
###         SMARTERS VPN PANEL  Setup 2023           ###
###                  Version 1.0                        ###
###                                                     ###
### Copyright (c) 2023                                ###
###                                                     ###
###                                                     ###
### Permission is hereby granted, free of charge, to    ###
### any person obtaining a copy of this script   and    ###
### associated documentation file,to deal in the        ###
### Script without restriction, including without       ###
### limitation the rights to use, copy, modify,merge,   ###
### publish, distribute, copies of the Software and to  ###
### permit persons to whom the Script is furnished to   ###
### do so,subject to the following conditions:          ###
###                                                     ###
### The above and this permission notice shall be       ###
### included in all copies or substantial portions      ###
### of the Script.                                      ###
###                                                     ###
### THE SCRIPT IS PROVIDED "AS IS", WITHOUT WARRANTY    ###
### OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT  ###
### LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       ###
### FITNESS FOR A PARTICULAR PURPOSE AND NON-           ###
### INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR      ###
### COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES  ###
### OR OTHER LIABILITY, WHETHER IN AN ACTION OF         ###
### CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF   ###
### OR IN CONNECTION WITH THE SCRIPT OR THE USE OR      ###
### OTHER DEALINGS IN THE SCRIPT.                       ###
###########################################################
while getopts ":h:p:l:i:d:x:y:a:m:s:r:v:c:w:z:e:f:g:n:t:q:b:" arg;  do
case "${arg}" in

    h) PANELURL=${OPTARG}
    ;;
    p) PORT=${OPTARG}
    ;;
    l) PROTOCOL=${OPTARG}
    ;;
    i) IPV6_SUPPORT=${OPTARG}
    ;;
    d) DNS=${OPTARG}
    ;;
    x) DNS1=${OPTARG}
    ;;
    y) DNS2=${OPTARG}
    ;;
    a) APIKEY=${OPTARG}
    ;;
    m) YOUR_RADIUS_SERVER_IP=${OPTARG}
    ;;
    s) RADIUS_SECRET=${OPTARG}
    ;;
    v) VPNTYPE=${OPTARG}
    ;;
    w) PROXYSERVER=${OPTARG}
    ;;
    z) PROXYPORT=${OPTARG}
    ;;
    r) PROXYHEADER=${OPTARG}
    ;;
    e) PROXYRETRY=${OPTARG}
    ;;
    f) CUSTOMHEADER=${OPTARG}
    ;;
    g) LOGSTORE=${OPTARG}
    ;;
    n) CLIENTHOSTNAME=${OPTARG}
    ;;
    t) HMAC_ALG=${OPTARG}
    ;;
    q) CIPHER=${OPTARG}
    ;;
    b) CCCIPHER=${OPTARG}
    ;;
    esac
done

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
SYS_DT=$(date +%F-%T)

exiterr()  { echo "Error: $1" >&2; exit 1; }
exiterr2() { exiterr "'apt-ge	t install' failed."; }
conf_bk() { /bin/cp -f "$1" "$1.old-$SYS_DT" 2>/dev/null; }
bigecho() { echo; echo "## $1"; echo; }
colorecho() { echo; echo -e "\x1b[32;40m \e[32;1m ##"$1"\x1b[m"; echo; }
bold=$(tput bold)
normal=$(tput sgr0)
LOG_FILE=`basename $0 ".sh"`
INSTALLATION_SCRIPT=`basename $0 ".sh"`
OS="ubuntu"
export DEBIAN_FRONTEND=noninteractive
# remove old log file if exists
if [[ -e /root/install-vpn-smartersvpnpanel.log ]]; then

rm /root/install-vpn-smartersvpnpanel.log 1>>$LOG_FILE.log 2>&1

fi

TOTAL_PARTS=14
log_progress() { echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` [PROGRESS] Part $1/$TOTAL_PARTS ($2%) - $3" 1>>$LOG_FILE.log 2>&1; }

#### Defining Functions for VPN Setup ########
func_status()
        {
         if [[ $1 != 0 ]]
         then
               echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: ERROR: failed." 
               exit
         fi
        }

colorecho "VPN Server Installation Started...." 1>>$LOG_FILE.log 2>&1
log_progress 1 5 "Initialization - Printing Variables"


echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` VPN Server Setup: INFO: Printing Variables." 1>>$LOG_FILE.log 2>&1

[[ ! -z $PANELURL ]] && echo "${bold}PANELURL:${normal}" $PANELURL 1>>$LOG_FILE.log 2>&1
[[ ! -z $PORT ]] && echo "${bold}PORT:${normal}" $PORT 1>>$LOG_FILE.log 2>&1
[[ ! -z $PROTOCOL ]] && echo "${bold}PROTOCOL:${normal}" $PROTOCOL 1>>$LOG_FILE.log 2>&1
[[ ! -z $IPV6_SUPPORT ]] && echo "${bold}IPV6_SUPPORT:${normal}" $IPV6_SUPPORT 1>>$LOG_FILE.log 2>&1
[[ ! -z $DNS ]] && echo "${bold}DNS:${normal}" $DNS 1>>$LOG_FILE.log 2>&1
[[ ! -z $DNS1 ]] && echo "${bold}DNS1:${normal}" $DNS1 1>>$LOG_FILE.log 2>&1
[[ ! -z $DNS2 ]] && echo "${bold}DNS2:${normal}" $DNS2 1>>$LOG_FILE.log 2>&1
[[ ! -z $APIKEY ]] && echo "${bold}APIKEY:${normal}" $APIKEY 1>>$LOG_FILE.log 2>&1
[[ ! -z $YOUR_RADIUS_SERVER_IP ]] && echo "${bold}YOUR_RADIUS_SERVER_IP:${normal}" $YOUR_RADIUS_SERVER_IP 1>>$LOG_FILE.log 2>&1
[[ ! -z $RADIUS_SECRET ]] && echo "${bold}RADIUS_SECRET:${normal}" $RADIUS_SECRET 1>>$LOG_FILE.log 2>&1
[[ ! -z $VPNTYPE ]] && echo "${bold}VPNTYPE:${normal}" $VPNTYPE 1>>$LOG_FILE.log 2>&1
[[ ! -z $PROXYSERVER ]] && echo "${bold}PROXYSERVER:${normal}" $PROXYSERVER 1>>$LOG_FILE.log 2>&1
[[ ! -z $PROXYPORT ]] && echo "${bold}PROXYPORT:${normal}" $PROXYPORT 1>>$LOG_FILE.log 2>&1
[[ ! -z $PROXYHEADER ]] && echo "${bold}PROXYHEADER:${normal}" $PROXYHEADER 1>>$LOG_FILE.log 2>&1
[[ ! -z $CUSTOMHEADER ]] && echo "${bold}CUSTOMHEADER:${normal}" $CUSTOMHEADER 1>>$LOG_FILE.log 2>&1
[[ ! -z $REMOVED ]] && echo "${bold}REMOVED:${normal}" $REMOVED 1>>$LOG_FILE.log 2>&1
[[ ! -z $LOGSTORE ]] && echo "${bold}LOGSTORE:${normal}" $LOGSTORE 1>>$LOG_FILE.log 2>&1
[[ ! -z $CLIENTHOSTNAME ]] && echo "${bold}CLIENTHOSTNAME:${normal}" $CLIENTHOSTNAME 1>>$LOG_FILE.log 2>&1
[[ ! -z $HMAC_ALG ]] && echo "${bold}HMAC_ALG:${normal}" $HMAC_ALG 1>>$LOG_FILE.log 2>&1
[[ ! -z $CCCIPHER ]] && echo "${bold}CCCIPHER:${normal}" $CCCIPHER 1>>$LOG_FILE.log 2>&1
[[ ! -z $CIPHER ]] && echo "${bold}CIPHER:${normal}" $CIPHER 1>>$LOG_FILE.log 2>&1
# check if CLIENTHOSTNAME is hostname or IP
if [[ $CLIENTHOSTNAME =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
echo "$CLIENTHOSTNAME is an IP ADDRESS!!" 1>>$LOG_FILE.log 2>&1

SERVER_IP_ADDRESS=$CLIENTHOSTNAME
SERVER_IP_ADDRESS_OR_HOSTNAME=$SERVER_IP_ADDRESS

#echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` ${bold}CLIENTHOSTNAME:${normal}" $CLIENTHOSTNAME 1>>$LOG_FILE.log 2>&1
elif [[ $CLIENTHOSTNAME =~ ^[a-zA-Z0-9]+([\-\.]{1}[a-zA-Z0-9]+)*\.[a-zA-Z]{2,5}$ ]]
then
echo "$CLIENTHOSTNAME is a Hostname!!" 1>>$LOG_FILE.log 2>&1

SERVER_HOSTNAME=$CLIENTHOSTNAME
SERVER_IP_ADDRESS_OR_HOSTNAME="@${SERVER_HOSTNAME}"

#echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` ${bold}CLIENTHOSTNAME:${normal}" $CLIENTHOSTNAME 1>>$LOG_FILE.log 2>&1
else
echo "Installation Error: Invalid IP OR Hostname!!" 1>>$LOG_FILE.log 2>&1
fi

log_progress 2 10 "Detecting Server IP Address"
echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` VPN Server Setup: INFO: Detecting Server IP Address." 1>>$LOG_FILE.log 2>&1

if ! PUBLIC_IP=$(curl ipinfo.io/ip)
then
echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` VPN Server Setup: Failed: Server IP Address Not Found !!." 1>>$LOG_FILE.log 2>&1
exit
else
echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` ${bold}Server IP Address:${normal}" $PUBLIC_IP 1>>$LOG_FILE.log 2>&1
fi


echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` VPN Server Setup: INFO: VPN setup in progress... Please be patient." 1>>$LOG_FILE.log 2>&1

log_progress 3 18 "StrongSwan Cleanup - Removing Old Installation"
#### before installation, we have to remove first if it's alreday installed
if [ -e "/etc/ipsec.conf" ] || [ -d "/etc/ipsec.d/" ]
then
    echo "${bold}VPN Server Setup: INFO:Found Strongswan Installed. Started removing it...${normal}" 1>>$LOG_FILE.log 2>&1
    apt-get remove strongswan strongswan-pki libcharon-standard-plugins libstrongswan libstrongswan-standard-plugins strongswan-charon strongswan-libcharon strongswan-starter -yq 1>>$LOG_FILE.log 2>&1
    apt-get autoremove -yq 1>>$LOG_FILE.log 2>&1
    apt-get purge strongswan -yq 1>>$LOG_FILE.log 2>&1

# Removing if any files and folders related to strongs/ipsec

if [ -d "/etc/ipsec.d/" ]
then
rm -rf /etc/ipsec.d/ 1>>$LOG_FILE.log 2>&1

echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` Removed /etc/ipsec.d/ directory successfully" 1>>$LOG_FILE.log 2>&1

fi

if [[ -e /etc/ipsec.conf ]]; then

rm /etc/ipsec.conf 1>>$LOG_FILE.log 2>&1

echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` Removed /etc/ipsec.conf file successfully" 1>>$LOG_FILE.log 2>&1

fi

if [[ -e /etc/ipsec.secrets ]]; then

rm /etc/ipsec.secrets

echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` Removed /etc/ipsec.secrets file successfully" 1>>$LOG_FILE.log 2>&1
fi
echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` VPN Server Setup: INFO: ikev2/Strongswan removed successfully" 1>>$LOG_FILE.log 2>&1
fi


log_progress 4 26 "Certbot Cleanup - Removing Old Certificates"
## Removing Certbot and existings certs if exists 

if [ -d "/etc/letsencrypt/" ] # first checking if letsencrypt folder there
then
echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` VPN Server Setup: Info: Found Certbot Installed" 1>>$LOG_FILE.log 2>&1

if [ -d "/etc/letsencrypt/live" ] #before getting the sub-directories (domain name directories), we haev to chedck if main directory(live) exits
then

if [ $(ls -A "/etc/letsencrypt/live") ] # it returns the directories names 

then

echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` VPN Server Setup: Info: Found /etc/letsencrypt/live directory not empty" 1>>$LOG_FILE.log 2>&1

for file in /etc/letsencrypt/live/*; do

echo "Deleting Certificate for domain:" "$(basename "$file")" 1>>$LOG_FILE.log 2>&1

sudo certbot delete --cert-name "$(basename "$file")" 1>>$LOG_FILE.log 2>&1

done

echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` Removed all existing certificates " 1>>$LOG_FILE.log 2>&1
fi

fi
echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` starting removing certbot and cleaning it completely " 1>>$LOG_FILE.log 2>&1

apt-get remove certbot -yq 1>>$LOG_FILE.log 2>&1
apt autoremove -yq 1>>$LOG_FILE.log 2>&1 # it removes the un-neccessary dependencies 
apt purge certbot -yq 1>>$LOG_FILE.log 2>&1 # this removes certbot completely otherwise, you can check dpkg -l *certbot*

rm -rf /etc/letsencrypt/
rm -rf /var/lib/letsencrypt/
rm -rf /var/log/letsencrypt/
echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` Removed Certbot and its folders/files completely  " 1>>$LOG_FILE.log 2>&1

fi

log_progress 5 33 "System Update - apt-get update"
echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` VPN Server Setup: INFO: Populating apt-get cache...." 1>>$LOG_FILE.log 2>&1
apt-get -yq update 1>>$LOG_FILE.log 2>&1
STATUS=`echo $?`
func_status "$STATUS"
 
echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` VPN Server setup: INFO: System updates completed successfully." 1>>$LOG_FILE.log 2>&1


log_progress 6 40 "Package Installation - StrongSwan and Certbot"
#### Time to install strongswan and certbot

#sudo apt-get install strongswan strongswan-pki libstrongswan-standard-plugins strongswan-libcharon libcharon-standard-plugins libcharon-extra-plugins moreutils certbot net-tools moreutils vnstat python3 -yq 1>>$LOG_FILE.log 2>&1
sudo apt install strongswan strongswan-pki libcharon-extra-plugins libcharon-extauth-plugins libstrongswan-extra-plugins libtss2-tcti-tabrmd0 moreutils certbot net-tools moreutils vnstat python3 -yq 1>>$LOG_FILE.log 2>&1
STATUS=`echo $?`
func_status "$STATUS"
echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` VPN Server Setup: Success: Strongswan && Certbot Installed" 1>>$LOG_FILE.log 2>&1

count=0
APT_LK=/var/lib/apt/lists/lock
PKG_LK=/var/lib/dpkg/lock
while fuser "$APT_LK" "$PKG_LK" >/dev/null 2>&1 \
  || lsof "$APT_LK" >/dev/null 2>&1 || lsof "$PKG_LK" >/dev/null 2>&1; do
  [ "$count" = "0" ] && bigecho "Waiting for apt to be available..."
  [ "$count" -ge "60" ] && exiterr "Could not get apt/dpkg lock."
  count=$((count+1))
  printf '%s' '.'
  sleep 3
done

log_progress 7 48 "SSL Certificate - Let's Encrypt (certbot)"
#sleep 120 # giving time to the domain to be propagated 
if [[ ! -z $SERVER_HOSTNAME ]]
then

sudo certbot certonly --standalone --agree-tos --register-unsafely-without-email -d $SERVER_HOSTNAME 1>>$LOG_FILE.log 2>&1

sudo ln -s /etc/letsencrypt/live/$SERVER_HOSTNAME/fullchain.pem /etc/ipsec.d/certs 1>>$LOG_FILE.log 2>&1
sudo ln -s /etc/letsencrypt/live/$SERVER_HOSTNAME/privkey.pem /etc/ipsec.d/private 1>>$LOG_FILE.log 2>&1
sudo ln -s /etc/letsencrypt/live/$SERVER_HOSTNAME/chain.pem /etc/ipsec.d/cacerts 1>>$LOG_FILE.log 2>&1

sudo chmod 755 /etc/letsencrypt/live/$SERVER_HOSTNAME/fullchain.pem 1>>$LOG_FILE.log 2>&1
sudo chmod 755 /etc/letsencrypt/live/$SERVER_HOSTNAME/privkey.pem 1>>$LOG_FILE.log 2>&1
sudo chmod 755 /etc/letsencrypt/live/$SERVER_HOSTNAME/chain.pem 1>>$LOG_FILE.log 2>&1


#######renew script start ##############################    
cat >> /etc/letsencrypt/renewal-hooks/deploy/renewal.sh <<EOF   
#!/bin/sh
ipsec restart
EOF
chmod +x /etc/letsencrypt/renewal-hooks/deploy/renewal.sh 1>>$LOG_FILE.log 2>&1
#######renew script End ##############################
fi
log_progress 8 55 "IPsec Configuration - ipsec.conf and strongswan.conf"
# creating ipsec.conf file 
cat >> /etc/ipsec.conf <<EOF
config setup
        strictcrlpolicy=yes
        uniqueids=never
conn ikev2
        auto=add
        keyexchange=ikev2
        forceencaps=yes
        dpdaction=clear
        dpddelay=300s
        rekey=no
        left=%any
        leftid=$SERVER_IP_ADDRESS_OR_HOSTNAME
        leftcert=fullchain.pem
        leftsendcert=always
        leftsubnet=0.0.0.0/0
        right=%any
        rightid=%any
        #rightauth=eap-mschapv2
        rightauth=eap-radius
        rightdns=8.8.8.8,8.8.4.4
        #rightsourceip=10.8.0.0/16
        rightsourceip=10.10.10.0/24
        rightsendcert=never
        eap_identity=%identity
        ike=chacha20poly1305-sha512-curve25519-prfsha512,aes256gcm16-sha384-prfsha384-ecp384,aes256-sha1-modp1024,aes128-sha1-modp1024,3des-sha1-modp1024,aes256-sha256-modp2048!
        esp=chacha20poly1305-sha512,aes256gcm16-ecp384,aes256-sha256,aes256-sha1,3des-sha1!
EOF

echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` VPN Server Setup: Success: /etc/ipsec.conf file created with expected content" 1>>$LOG_FILE.log 2>&1
cat /etc/ipsec.conf 1>>$LOG_FILE.log 2>&1

cat /dev/null > /etc/strongswan.conf  # clear first
cat >> /etc/strongswan.conf <<EOF
charon {
    load_modular = yes
         plugins {
                  include strongswan.d/charon/*.conf
    eap-radius {
          accounting = yes
         servers {
    server-a {
      address = $YOUR_RADIUS_SERVER_IP
      secret = $RADIUS_SECRET
      auth_port = 1812   # default
      acct_port = 1813   # default
 
    }
  }
  }
  }
  include strongswan.d/*.conf
  }
EOF
cat /dev/null > /etc/ipsec.secrets
cat >> /etc/ipsec.secrets <<EOF
: RSA "privkey.pem"
EOF
echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` VPN Server Setup: Success: /etc/strongswan.conf file created with expected content" 1>>$LOG_FILE.log 2>&1
cat /etc/strongswan.conf 1>>$LOG_FILE.log 2>&1


log_progress 9 62 "Firewall Rules - iptables and sysctl"
ETH0ORSIMILAR=$(ip route get 1.1.1.1 | awk -- '{printf $5}')
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections 
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections 
sudo apt-get -yq install iptables-persistent 1>>$LOG_FILE.log 2>&1

iptables -P INPUT   ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT  ACCEPT
 
iptables -F
iptables -t nat -F
iptables -t mangle -F
 
 
iptables -A INPUT -p udp --dport  500 -j ACCEPT
iptables -A INPUT -p udp --dport 4500 -j ACCEPT
 
# forward VPN traffic anywhere
iptables -A FORWARD --match policy --pol ipsec --dir in  --proto esp -s 10.10.10.0/24 -j ACCEPT
iptables -A FORWARD --match policy --pol ipsec --dir out --proto esp -d 10.10.10.0/24 -j ACCEPT
 
iptables -P FORWARD ACCEPT
 
# reduce MTU/MSS values for dumb VPN clients
iptables -t mangle -A FORWARD --match policy --pol ipsec --dir in -s 10.10.10.0/24 -o $ETH0ORSIMILAR -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360
 
# masquerade VPN traffic over eth0, etc.
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o $ETH0ORSIMILAR -m policy --pol ipsec --dir out -j ACCEPT  # exempt IPsec traffic from masquerading
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o $ETH0ORSIMILAR -j MASQUERADE

# Saving Iptables rules
iptables-save > /etc/iptables/rules.v4

echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` VPN Server Setup: Success: Updating sysctl settings..." 1>>$LOG_FILE.log 2>&1

if ! grep -qs "smarters VPN script" /etc/sysctl.conf; then
  conf_bk "/etc/sysctl.conf"


cat >> /etc/sysctl.conf <<EOF
# Added by Smarters VPN script
net.ipv4.ip_forward = 1
net.ipv4.ip_no_pmtu_disc = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.disable_ipv6 = 1
EOF
fi

sysctl -p 1>>$LOG_FILE.log 2>&1
if [[ ! -z $SERVER_HOSTNAME ]]
then
sudo ln -s /etc/apparmor.d/usr.lib.ipsec.charon /etc/apparmor.d/disable/ 1>>$LOG_FILE.log 2>&1
sudo ln -s /etc/apparmor.d/usr.lib.ipsec.stroke /etc/apparmor.d/disable/ 1>>$LOG_FILE.log 2>&1
sudo apparmor_parser -R /etc/apparmor.d/usr.lib.ipsec.charon 1>>$LOG_FILE.log 2>&1
sudo apparmor_parser -R /etc/apparmor.d/usr.lib.ipsec.stroke 1>>$LOG_FILE.log 2>&1
fi
ipsec restart 1>>$LOG_FILE.log 2>&1


echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` VPN Server Setup: Success: Ikev2 - ipsec with strongswan installed with domain name" 1>>$LOG_FILE.log 2>&1
###### Socks5 Installation using Dante-server #### 
if [[ $SOCKS5 == "yes" ]]; then
echo "Socks5 Installation using Dante-server"

sudo apt install dante-server -y 1>>$LOG_FILE.log 2>&1
rm /etc/danted.conf 1>>$LOG_FILE.log 2>&1
 
cat >> /etc/danted.conf <<EOF
debug: 2
logoutput: syslog
user.privileged: root
user.unprivileged: nobody
logoutput: /var/log/sockd.log
# The listening network interface or address.
internal: 0.0.0.0 port=1080
# The proxying network interface or address.
external: $ETH0ORSIMILAR
# socks-rules determine what is proxied through the external interface.
#socksmethod: username
socksmethod: pam
# client-rules determine who can connect to the internal interface.
#clientmethod: none
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}
EOF
echo "Dante-server configuration file" 1>>$LOG_FILE.log 2>&1
cat /etc/danted.conf 1>>$LOG_FILE.log 2>&1
echo "Start installation for pam radius" 1>>$LOG_FILE.log 2>&1
apt-get install libpam-radius-auth libpam0g-dev gcc -y 1>>$LOG_FILE.log 2>&1
rm  /etc/pam_radius_auth.conf 1>>$LOG_FILE.log 2>&1
cat >> /etc/pam_radius_auth.conf <<EOF
$YOUR_RADIUS_SERVER_IP         $RADIUS_SECRET      1
EOF
if [[ -e /etc/pam.d/sockd ]]; then
rm /etc/pam.d/sockd
echo "` date +"%Y%m%d"` `date +"%H:%M:%S"` Removed /etc/pam.d/sockd file successfully" 
fi

cat >> /etc/pam.d/sockd <<EOF
auth sufficient pam_radius_auth.so
account sufficient pam_radius_auth.so
EOF
service danted restart 1>>$LOG_FILE.log 2>&1
##### Socks5 Installation Done ########
fi

log_progress 10 70 "Usage and Monitoring Setup - Apache, Cron, Speed Test"
echo "Usage Integration Started" 1>>$LOG_FILE.log 2>&1
#######Start Setup usage Script #######################
#check if usage script already installed
if [[ -e /root/usage-script.sh ]]; then
rm /root/usage-script.sh
echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` Removed /root/usage-script.sh file successfully" 1>>$LOG_FILE.log 2>&1
fi
# if [[ -e /root/check_services.sh ]]; then
# rm /root/check_services.sh
# echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` Removed /root/check_services.sh file successfully" 1>>$LOG_FILE.log 2>&1
# fi

wget -P /root https://raw.githubusercontent.com/whmcs-smarters/installscripts/main/usage-script.sh 1>>$LOG_FILE.log 2>&1
# wget -P /root https://raw.githubusercontent.com/whmcs-smarters/usage-script/main/check_services.sh 1>>$LOG_FILE.log 2>&1
# chmod +x /root/check_services.sh 1>>$LOG_FILE.log 2>&1
chmod +x /root/usage-script.sh 1>>$LOG_FILE.log 2>&1
apt-get install -y apache2 1>>$LOG_FILE.log 2>&1
#######End Strart Setup usage Script #######################
#######Start Web ##########################################
sed -i "s/Listen 80/Listen 4545/g" /etc/apache2/ports.conf
sed -i "s/Listen 443/Listen 4546/g" /etc/apache2/ports.conf
sudo mkdir -p /var/www/usage 1>>$LOG_FILE.log 2>&1
sudo chmod -R 755 /var/www/usage/ 1>>$LOG_FILE.log 2>&1

cat > /etc/apache2/sites-available/usage.conf <<EOF
<VirtualHost *:4545>
ServerAdmin admin@localhost.com
ServerName $CLIENTHOSTNAME
ServerAlias $CLIENTHOSTNAME
DocumentRoot /var/www/usage/
ErrorLog ${APACHE_LOG_DIR}/error.log
CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
# Script to identify the server and services status
sudo a2ensite usage.conf  1>>$LOG_FILE.log 2>&1
sudo a2dissite 000-default.conf 1>>$LOG_FILE.log 2>&1
sudo systemctl restart apache2 1>>$LOG_FILE.log 2>&1
#sudo apache2ctl configtest
#######End Web#############################################
#########Set Cron Job######################################
crontab -l > cron_backup
job=$(grep  "usage-script.sh" "cron_backup" -R)
if [ "$job" == "*/5 * * * * sudo /root/usage-script.sh" ];
        then
                echo "your cron job already exists" 1>>$LOG_FILE.log 2>&1
else
                echo "*/5 * * * * sudo /root/usage-script.sh" >> cron_backup
                echo "Usage calculation add to cronjob" 1>>$LOG_FILE.log 2>&1
fi

# job=$(grep  "check_services.sh" "cron_backup" -R)
# if [ "$job" == "*/5 * * * * sudo /root/check_services.sh  > /dev/null 2>&1" ];
#         then
#                 echo "your cron job already exists" 1>>$LOG_FILE.log 2>&1
# else
#                 echo "*/5 * * * * sudo /root/check_services.sh  > /dev/null 2>&1" >> cron_backup
#                 echo "Server and Services Status Script add to cronjob" 1>>$LOG_FILE.log 2>&1
# fi
crontab cron_backup 1>>$LOG_FILE.log 2>&1
rm cron_backup 1>>$LOG_FILE.log 2>&1
service cron restart 1>>$LOG_FILE.log 2>&1
#########End Cron job########################################
echo "Calculating Download and Upload Speed on Server"  1>>$LOG_FILE.log 2>&1
#apt install python -y // Depreciated command 
apt install 2to3 python2-minimal python2 dh-python python-is-python3 -y
curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -  >> /tmp/speed.txt
speed1=$(cat /tmp/speed.txt | grep -i "Download:")
speed2=$(cat /tmp/speed.txt |grep -i "Upload:")
echo $speed1 > /var/www/usage/speed1.txt 
echo $speed2 >> /var/www/usage/speed2.txt
rm -Rf /tmp/speed*
echo "Usage Integration Done and info saved at /var/www/usage/speed1.txt" 1>>$LOG_FILE.log 2>&1

echo "Read root/openvpn_log_file.txt for more details" 1>>$LOG_FILE.log 2>&1


#removing previous log 

#log=/root/openvpn_log_file.txt
log_progress 11 78 "OpenVPN Setup - Install and Configure"
log=/root/install-vpn-smartersvpnpanel.log
echo Openvpn server configuration start on $(date) >> $log
rm /root/openvpn_* >> $log
{
echo checking openvpn server install or not >> $log 
vpn1=$(ifconfig)
if [[ $vpn1 == *tun* || -e "/etc/openvpn/server.conf" ]]; then
echo OpenVPN server running and removing everything OpenVPN related>> $log
systemctl disable openvpn@server >> $log
systemctl stop openvpn@server >> $log
# Remove customised service
rm /etc/systemd/system/openvpn\@.servic >> $log
# Remove the iptables rules related to the script
systemctl stop iptables-openvpn >> $log
# Cleanup openvpn service with iptables rules
systemctl disable iptables-openvpn >> $log	
rm /etc/systemd/system/iptables-openvpn.service	>> $log
systemctl daemon-reload	>> $log
rm /etc/iptables/add-openvpn-rules.sh >> $log	
rm /etc/iptables/rm-openvpn-rules.sh >> $log	
rm /etc/sysctl.d/20-openvpn.conf >> $log	
#Remove openvpn pacakge 
apt-get remove --purge -y openvpn >> $log	
# Cleanup openvpn conf files and log files
rm -Rf /root/openvpnserver_instalation.log >> $log
rm -Rf /root/openvpn_server_start.log >> $log
find /home/ -maxdepth 2 -name "*.ovpn" -delete >> $log
find /root/ -maxdepth 1 -name "*.ovpn" -delete >> $log
rm -rf /etc/openvpn >> $log
rm -rf /usr/share/doc/openvpn* >> $log
rm -f /etc/sysctl.d/99-openvpn.conf >> $log
rm -rf /var/log/openvpn >> $log
echo "####Openvpn server sever fully removed#####" >> $log	
else
       echo "OpenVPN server is not running" >> $log
fi
#install OpenVPN server with certificate 
echo "OpenVPN server installation start" >> $log
apt-get install -y openvpn iptables openssl wget ca-certificates curl easy-rsa >> $log
#create server certificate and client certificate
#sudo wget -O ~/easy-rsa.tgz https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.7/EasyRSA-3.0.7.tgz >> $log
mkdir -p /etc/openvpn/easy-rsa >> $log 
ln -s /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/ >> $log
#tar xzf ~/easy-rsa.tgz --strip-components=1 --directory /etc/openvpn/easy-rsa >> $log
#rm -f ~/easy-rsa.tgz >> $log
cd /etc/openvpn/easy-rsa/ || return >> $log
echo "set_var EASYRSA_ALGO ec 
set_var EASYRSA_CURVE prime256v1" >vars 
SERVER_CN="cn_$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)" 
echo "$SERVER_CN" >SERVER_CN_GENERATED 
SERVER_NAME="server_$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)"
echo "$SERVER_NAME" >SERVER_NAME_GENERATED 
# (Optional) vars do not need to be executable, but harmless if you want to keep them
chmod +x vars

# Save the generated names (from your earlier steps)
echo "$SERVER_CN" > SERVER_CN_GENERATED
echo "$SERVER_NAME" > SERVER_NAME_GENERATED

# IMPORTANT: Do NOT set EASYRSA_REQ_CN in vars (avoids CN conflict on Easy-RSA 3.1.x / Ubuntu 24.04)
# echo "set_var EASYRSA_REQ_CN $SERVER_CN" >> vars    # <-- REMOVE THIS LINE

echo "VARS file prepared for certificate generation" >> "$log"
cat vars >> "$log"
echo "Please wait while server and client certificates are created..." >> "$log"

# Initialize PKI
./easyrsa init-pki >> "$log" 2>&1

# Create CA (no passphrase)
./easyrsa --batch build-ca nopass >> "$log" 2>&1   # create server CA file

# Build server cert (CN will be the NAME you pass here; works for both Easy-RSA 3.0.x and 3.1.x)
./easyrsa --batch build-server-full "$SERVER_NAME" nopass >> "$log" 2>&1

# Generate a long-lived CRL
EASYRSA_CRL_DAYS=36500 ./easyrsa gen-crl >> "$log" 2>&1

# Generate tls-crypt key (new syntax first for OpenVPN 2.6+, fall back to old syntax for older OpenVPN)
openvpn --genkey secret /etc/openvpn/tls-crypt.key >> "$log" 2>&1 \
  || openvpn --genkey --secret /etc/openvpn/tls-crypt.key >> "$log" 2>&1

echo "Keys/certs generation complete" >> "$log"

echo successfully created tls-crypt.key >> $log
cat /etc/openvpn/tls-crypt.key >> $log   
cp pki/ca.crt pki/private/ca.key "pki/issued/$SERVER_NAME.crt" "pki/private/$SERVER_NAME.key" /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn >> $log
#Create client certicate/client name = client01
./easyrsa --batch build-client-full client01 nopass
#./easyrsa build-client-full client01 nopass >> $log
#create opevpn server conf
echo "port $PORT
proto $PROTOCOL 
dev tun
user nobody
group nogroup
persist-key
persist-tun
keepalive 10 120
topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
dh none
ecdh-curve prime256v1
tls-crypt tls-crypt.key
duplicate-cn
ca ca.crt
cert $SERVER_NAME.crt
key $SERVER_NAME.key
auth $HMAC_ALG
cipher $CIPHER
tls-server
tls-version-min 1.2
#tls-cipher $CCCIPHER
status /var/log/openvpn/status.log
log-append /var/log/openvpn/openvpn.log
verb 3
plugin /etc/openvpn/radius/radiusplugin.so /etc/openvpn/radius/radius.cnf" >> /etc/openvpn/server.conf
cat >> /etc/openvpn/server.conf << EOF
push "dhcp-option DNS $DNS1"
push "dhcp-option DNS $DNS2"
push "redirect-gateway def1 bypass-dhcp"
EOF
echo "#########openvpn server conf################" >> $log 
cat /etc/openvpn/server.conf >> $log
echo "#########Checking client OVPN File############" >> $log 
#create Client conf file
echo "client
proto $PROTOCOL
explicit-exit-notify
remote $CLIENTHOSTNAME $PORT
dev tun
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verify-x509-name $SERVER_NAME name
auth-user-pass
auth $HMAC_ALG
#auth-nocache
cipher $CIPHER
tls-client
tls-version-min 1.2
#tls-cipher $CCCIPHER
reneg-sec 0
ignore-unknown-option block-outside-dns
setenv opt block-outside-dns # Prevent Windows 10 DNS leak
verb 3">> /etc/openvpn/client-template.txt
touch /root/client.ovpn						
cp /etc/openvpn/client-template.txt "/root/client.ovpn"
	{
		echo "<ca>"
		cat "/etc/openvpn/easy-rsa/pki/ca.crt"
		echo "</ca>"
		echo "<cert>"
		awk '/BEGIN/,/END/' "/etc/openvpn/easy-rsa/pki/issued/client01.crt"
		echo "</cert>"
		echo "<key>"
		cat "/etc/openvpn/easy-rsa/pki/private/client01.key"
		echo "</key>"
		echo "<tls-crypt>"
		cat "/etc/openvpn/tls-crypt.key"
		echo "</tls-crypt>"
		
	} >>"/root/client.ovpn"
cat /root/client.ovpn >> $log
echo OVPN file created on root home folder  >> $log
cd || return
echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` [PROGRESS] Part 12/$TOTAL_PARTS (86%) - RADIUS Client Setup" 1>>$LOG_FILE.log 2>&1
#RadiusClient Installation Started
echo "#######Radius Client Installation Started#########" >> $log  
echo "##### checking Ubuntu Version ######" >> $log
# Check if the lsb_release command is available
if ! command -v lsb_release &>/dev/null; then
  echo "lsb_release command not found. Please install the lsb-release package." >> $log
  exit 1
fi
 # Get the Ubuntu version information
ubuntu_version=$(lsb_release -rs) >> $log       
# Check if the version is retrieved successfully
if [ -n "$ubuntu_version" ]; then
  echo "Ubuntu version: $ubuntu_version" >> $log
else
  echo "Failed to detect Ubuntu version." >> $log
  exit 1
fi

if [ -d "/root/radiusplugin_v2.1a_beta1" ] || [ -d "/etc/openvpn/radius" ];then #remove existing radius file
rm -r /root/radiusplugin_v2.1a_beta1* >> $log
rm -r /etc/openvpn/radius >> $log
fi
## Download the Radius Plugin and install
cd /root || return
wget https://github.com/whmcs-smarters/usage-script/raw/main/radiusplugin_v2.1a_beta1.tar.gz >> $log
#wget http://www.nongnu.org/radiusplugin/radiusplugin_v2.1a_beta1.tar.gz  >> $log # download radius pacakge and install 
tar xvf radiusplugin_v2.1a_beta1.tar.gz >> $log
cd radiusplugin_v2.1a_beta1 >> $log
# install dependencies for radius client
if [[ "$(echo "$ubuntu_version < 20.04" | bc -l)" -eq 1 ]]; then
    # For Ubuntu < 20.04 (e.g., 18.04)
    apt-get -y install libgcrypt11-dev build-essential >> $log
else
    # For Ubuntu >= 20.04
    apt install -y libgcrypt20-dev build-essential >> $log
fi

make >> $log
sleep 3
mkdir /etc/openvpn/radius >> $log
cp -r radiusplugin.so /etc/openvpn/radius >> $log 
conf_bk "/etc/openvpn/radius/radius.cnf" >> $log 
if [ -e "/etc/openvpn/radius/radius.cnf" ]; then
rm /etc/openvpn/radius/radius.cnf >> $log
fi
PUBLIC_IPV4=$(curl ipinfo.io/ip)
cat >> /etc/openvpn/radius/radius.cnf <<EOF
NAS-Identifier=$YOUR_RADIUS_SERVER_IP
Service-Type=5
Framed-Protocol=1
NAS-Port-Type=5
NAS-IP-Address=$PUBLIC_IP
OpenVPNConfig=/etc/openvpn/server.conf
subnet=255.255.255.0
overwriteccfiles=true
nonfatalaccounting=false
server
{
acctport=1813
authport=1812
name=$YOUR_RADIUS_SERVER_IP
retry=1
wait=1
sharedsecret=$RADIUS_SECRET
}

EOF
echo "Radiusclient Installation Done" >> $log
echo "#######Radius client configuration for Openvpn #########" >> $log  
cat /etc/openvpn/radius/radius.cnf >> $log	
#Create IPv4 table rules and port forwarding on Sever
echo "Create IPv4 table rules and port forwarding on Sever"
# Create log dir
mkdir -p /var/log/openvpn 
# Enable routing
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.d/20-openvpn.conf 
echo "Enable routing" >> $log
cat /etc/sysctl.d/20-openvpn.conf >> $log
# Apply sysctl rules
sysctl --system 

NIC=$(ip route get 8.8.8.8 | awk -- '{printf $5}')
# Add iptables rules in two scripts
mkdir /etc/iptables 

# Script to add rules
echo "#!/bin/sh
iptables -t nat -I POSTROUTING 1 -s 10.8.0.0/24 -o $NIC -j MASQUERADE
iptables -I INPUT 1 -i tun0 -j ACCEPT
iptables -I FORWARD 1 -i $NIC -o tun0 -j ACCEPT
iptables -I FORWARD 1 -i tun0 -o $NIC -j ACCEPT
iptables -I INPUT 1 -i $NIC -p $PROTOCOL --dport $PORT -j ACCEPT" > /etc/iptables/add-openvpn-rules.sh
echo "IPtable rules for OpenVPN client connection" >> $log
cat /etc/iptables/add-openvpn-rules.sh >> $log
# Script to remove rules
echo "#!/bin/sh
iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o $NIC -j MASQUERADE
iptables -D INPUT -i tun0 -j ACCEPT
iptables -D FORWARD -i $NIC -o tun0 -j ACCEPT
iptables -D FORWARD -i tun0 -o $NIC -j ACCEPT
iptables -D INPUT -i $NIC -p $PROTOCOL --dport $PORT -j ACCEPT" > /etc/iptables/rm-openvpn-rules.sh
echo "Disable IPtable rules for OpenVPN connection"
cat /etc/iptables/rm-openvpn-rules.sh >> $log

chmod +x /etc/iptables/add-openvpn-rules.sh 
chmod +x /etc/iptables/rm-openvpn-rules.sh  

# Handle the rules via a systemd script
echo "#######Creating IPtable rules for openvpn as services#######" >> $log

echo "[Unit]
Description=iptables rules for OpenVPN
Before=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/etc/iptables/add-openvpn-rules.sh
ExecStop=/etc/iptables/rm-openvpn-rules.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/iptables-openvpn.service
cat /etc/systemd/system/iptables-openvpn.service >> $log

# Enable service and apply rules
systemctl daemon-reload 
systemctl enable iptables-openvpn 
systemctl start iptables-openvpn 
	
} &> /dev/null

#configure the OpenVPN service and add it to bootup
# Finally, restart and enable OpenVPN
cp /lib/systemd/system/openvpn\@.service /etc/systemd/system/openvpn\@.service 

# Workaround to fix OpenVPN service on OpenVZ
sed -i 's|LimitNPROC|#LimitNPROC|' /etc/systemd/system/openvpn\@.service  

# Another workaround to keep using /etc/openvpn/
sed -i 's|/etc/openvpn/server|/etc/openvpn|' /etc/systemd/system/openvpn\@.service 

systemctl start openvpn@server  >> $log
systemctl enable openvpn@server >> $log
# sleep 10
# vpn2=$(ifconfig)
# if [[ $vpn2 == *tun* ]]; then
# echo "OpenVPN server start successfully" >> $log
# cat /var/log/openvpn/openvpn.log 1>>/root/openvpn_server_start.log 2>&1
# echo -e "Save start logs in root/openvpn_server_start.log file" >> $log
# else
# echo -e "Openvpn server start not successful" >> $log
# cat /var/log/openvpn/openvpn.log 1>>openvpn_server_fail.log 2>&1
# echo -e "Save fail logs in root/openvpn_server_fail.log file" >> $log
# fi


# openvpn server configuration end
# Define file paths for OpenVPN and IKEv2 status
touch /var/www/usage/openvpn.txt
touch /var/www/usage/ikev2.txt
OPENVPN_STATUS_FILE="/var/www/usage/openvpn.txt"
IKEV2_STATUS_FILE="/var/www/usage/ikev2.txt"

echo "Check if the OpenVPN service is running" >> $log
if systemctl is-active openvpn@server > /dev/null 2>&1; then
echo "online" > $OPENVPN_STATUS_FILE
OPENVPN_STATUS="online"
else
echo "offline" > $OPENVPN_STATUS_FILE
OPENVPN_STATUS="offline"
fi

# Check if the IKEv2 service is running
if ipsec status > /dev/null 2>&1; then
echo "online" > $IKEV2_STATUS_FILE
IKEV2_STATUS="online"
else
echo "offline" > $IKEV2_STATUS_FILE
IKEV2_STATUS="offline"
fi
echo "#### Service Status for OpenVPN and Ikev2 ####" >> $log
echo "OpenVPN Status: $OPENVPN_STATUS" >> $log
echo "IKEv2 Status: $IKEV2_STATUS" >> $log

### Installing WireGuard Now
wireguard_install() {
  # --- WireGuard (server + 1 client) ---
  # NOTE: Your IKEv2 script already uses 10.10.10.0/24.
  # To avoid IP conflicts, WireGuard uses a different subnet by default here.
  local WG_IF="wg0"
  local WG_NET="10.66.66.0/24"
  local SERVER_ADDR="10.66.66.1/24"
  local CLIENT_ADDR="10.66.66.2/32"
  local WG_PORT="51820"
  local WG_MTU="1380"
  local CLIENT_DNS="${DNS1:-1.1.1.1}"

  local WG_DIR="/etc/wireguard"
  local SERVER_PRIV="$WG_DIR/server_private.key"
  local SERVER_PUB="$WG_DIR/server_public.key"
  local CLIENT_PRIV="$WG_DIR/client1_private.key"
  local CLIENT_PUB="$WG_DIR/client1_public.key"
  local WG_CONF="$WG_DIR/${WG_IF}.conf"
  local CLIENT_CONF="$WG_DIR/client1.conf"

  # Endpoint preference:
  # - If you have a hostname, use it
  # - else fall back to PUBLIC_IP
  local endpoint="${CLIENTHOSTNAME:-${PUBLIC_IP:-}}"
  if [[ -z "${endpoint}" ]]; then
    endpoint="YOUR_SERVER_PUBLIC_IP_OR_HOSTNAME"
  fi

  # Check if WireGuard is already installed
  if dpkg-query -W -f='${Status}' wireguard 2>/dev/null | grep -q "install ok installed"; then
    echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` WireGuard: INFO: WireGuard already installed. Cleaning old install/config and reinstalling..." 1>>$LOG_FILE.log 2>&1

    # Tear down running interface if present
    systemctl disable --now "wg-quick@${WG_IF}" >/dev/null 2>&1 || true
    ip link show "${WG_IF}" >/dev/null 2>&1 && ip link delete "${WG_IF}" >/dev/null 2>&1 || true

    # Remove previous config and key material
    rm -rf "${WG_DIR}" 1>>$LOG_FILE.log 2>&1 || true

    # Remove existing package before reinstall
    apt-get purge -y wireguard wireguard-tools iptables 1>>$LOG_FILE.log 2>&1
    apt-get autoremove -y 1>>$LOG_FILE.log 2>&1
  fi

  # Detect WAN iface
  local wan_iface
  wan_iface="$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
  if [[ -z "${wan_iface:-}" ]]; then
    echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` WireGuard: ERROR: Could not detect WAN interface" 1>>$LOG_FILE.log 2>&1
    return 1
  fi

  echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` WireGuard: INFO: Installing packages" 1>>$LOG_FILE.log 2>&1
  apt-get update -yq 1>>$LOG_FILE.log 2>&1
  apt-get install -yq wireguard iptables 1>>$LOG_FILE.log 2>&1
  apt-get install -yq qrencode >/dev/null 2>&1 || true

  # Enable forwarding (your script already does this, but safe to ensure)
  echo "net.ipv4.ip_forward=1" >/etc/sysctl.d/99-wireguard.conf
  sysctl --system >/dev/null 2>&1 || true

  # Generate fresh keys/config every run
  umask 077
  mkdir -p "$WG_DIR"
  rm -f "$SERVER_PRIV" "$SERVER_PUB" "$CLIENT_PRIV" "$CLIENT_PUB" "$WG_CONF" "$CLIENT_CONF" 1>>$LOG_FILE.log 2>&1 || true

  echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` WireGuard: INFO: Generating new keys" 1>>$LOG_FILE.log 2>&1
  wg genkey > "$SERVER_PRIV"
  wg pubkey < "$SERVER_PRIV" > "$SERVER_PUB"

  wg genkey > "$CLIENT_PRIV"
  wg pubkey < "$CLIENT_PRIV" > "$CLIENT_PUB"

  echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` WireGuard: INFO: Writing server config $WG_CONF" 1>>$LOG_FILE.log 2>&1
  {
    echo "[Interface]"
    echo "Address = ${SERVER_ADDR}"
    echo "ListenPort = ${WG_PORT}"
    echo "PrivateKey = $(cat "$SERVER_PRIV")"
    echo "MTU = ${WG_MTU}"
    echo
    echo "# NAT + forwarding on up/down"
    echo "PostUp   = sysctl -w net.ipv4.ip_forward=1"
    echo "PostUp   = iptables -t nat -A POSTROUTING -s ${WG_NET} -o ${wan_iface} -j MASQUERADE"
    echo "PostUp   = iptables -A FORWARD -i ${WG_IF} -j ACCEPT"
    echo "PostUp   = iptables -A FORWARD -o ${WG_IF} -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
    echo
    echo "PostDown = iptables -t nat -D POSTROUTING -s ${WG_NET} -o ${wan_iface} -j MASQUERADE"
    echo "PostDown = iptables -D FORWARD -i ${WG_IF} -j ACCEPT"
    echo "PostDown = iptables -D FORWARD -o ${WG_IF} -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
    echo
    echo "[Peer]"
    echo "PublicKey = $(cat "$CLIENT_PUB")"
    echo "AllowedIPs = ${CLIENT_ADDR}"
  } > "$WG_CONF"
  chmod 600 "$WG_CONF"

  echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` WireGuard: INFO: Writing client config $CLIENT_CONF" 1>>$LOG_FILE.log 2>&1
  {
    echo "[Interface]"
    echo "PrivateKey = $(cat "$CLIENT_PRIV")"
    echo "Address = ${CLIENT_ADDR}"
    echo "DNS = ${CLIENT_DNS}"
    echo "MTU = ${WG_MTU}"
    echo
    echo "[Peer]"
    echo "PublicKey = $(cat "$SERVER_PUB")"
    echo "Endpoint = ${endpoint}:${WG_PORT}"
    echo "AllowedIPs = 0.0.0.0/0"
    echo "PersistentKeepalive = 25"
  } > "$CLIENT_CONF"
  chmod 600 "$CLIENT_CONF"

  # Start WG
  echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` WireGuard: INFO: Enabling wg-quick@${WG_IF}" 1>>$LOG_FILE.log 2>&1
  systemctl enable --now "wg-quick@${WG_IF}" >/dev/null 2>&1 || true

  # Summary into log
  echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` WireGuard: SUCCESS: Installed. ServerConf=$WG_CONF ClientConf=$CLIENT_CONF" 1>>$LOG_FILE.log 2>&1

  # Optional: print QR to terminal (not log)
  if command -v qrencode >/dev/null 2>&1 && [[ -f "$CLIENT_CONF" ]]; then
    echo
    echo "WireGuard client QR (scan in WireGuard mobile app):"
    qrencode -t ansiutf8 < "$CLIENT_CONF" || true
    echo
    echo "WireGuard client config saved at: $CLIENT_CONF"
  else
    echo
    echo "WireGuard client config saved at: $CLIENT_CONF"
  fi

  return 0
}
echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` [PROGRESS] Part 13/$TOTAL_PARTS (93%) - WireGuard Installation" 1>>$LOG_FILE.log 2>&1
echo "Calling WireGuard Install Function" >> $log
wireguard_install

#  Sending back the status of installation
echo " Sending back the status of installation" >> $log

return_status=$(curl --data "api=$APIKEY&status=1&ip=$CLIENTHOSTNAME&services_status_openvpn=$OPENVPN_STATUS&service_status_ikev2=$IKEV2_STATUS&v=$VPNTYPE&VPNSERVERIP=$PUBLIC_IP&speed1=$speed1&speed2=$speed2" $PANELURL/api/v1/vpncallbackurl); 1>>$LOG_FILE.log 2>&1

echo $return_status >> $log
log_progress 14 100 "Installation Complete"
#cleaning files
rm /root/checkServerCompatibility.sh >> $log
rm /root/install-vpn-smartersvpnpanel.sh >> $log
exit 0
