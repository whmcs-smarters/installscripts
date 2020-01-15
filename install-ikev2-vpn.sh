#!/bin/bash
#Created by WHMCS-Smarters Team. We provide VPN Software Solution & Services for Business at www.whmcssmarters.com

while getopts ":h:a:m:s:r:" o
do
    case "${o}" in
    h) PANELURL=${OPTARG}
    ;;
    a) APIKEY=${OPTARG}
    ;;
    m) YOUR_RADIUS_SERVER_IP=${OPTARG}
    ;;
    s) RADIUS_SECRET=${OPTARG}
    ;;
    r) REMOVED=${OPTARG}
    ;;
    *) usage
    ;;
    esac
done
 
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
SYS_DT=$(date +%F-%T)

exiterr()  { echo "Error: $1" >&2; exit 1; }
exiterr2() { exiterr "'apt-get install' failed."; }
conf_bk() { /bin/cp -f "$1" "$1.old-$SYS_DT" 2>/dev/null; }
bigecho() { echo; echo "## $1"; echo; }

# Ikev2 VPN Server Installation # 
bigecho " Ikev2 VPN Installation Started ....."

if [ -z "$RADIUS_SECRET" ];then
  RADIUS_SECRET="testing123"
fi


#PUBLIC_IP=$(dig @resolver1.opendns.com -t A -4 myip.opendns.com +short)
#[ -z "$PUBLIC_IP" ] && PUBLIC_IP=$(wget -t 3 -T 15 -qO- http://ipv4.icanhazip.com)
PUBLIC_IP=$(curl ipinfo.io/ip)

echo " Public IP Address: $PUBLIC_IP"



vpnsetup() {

bigecho "Populating apt-get cache..."

export DEBIAN_FRONTEND=noninteractive

apt-get -yq update || exiterr "'apt-get update' failed."

bigecho "VPN setup in progress... Please be patient."

sudo apt install strongswan strongswan-pki libstrongswan-standard-plugins strongswan-libcharon libcharon-standard-plugins libcharon-extra-plugins moreutils -yq || exiterr2

echo " Strongswan Installed " 

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



echo " Making Directories for Certs files " 

if [ -d "~/pki/" ] 
then
    echo "Directory exists and removed "
rm -r ~/pki/
 
else
    echo "Message: Directory ~/pki/ does not exists,So creating..."
fi


mkdir -p ~/pki/ || exiterr " Directories not created "
mkdir -p ~/pki/cacerts/
mkdir -p ~/pki/certs/
mkdir -p ~/pki/private/


chmod 700 ~/pki

ipsec pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/ca-key.pem

ipsec pki --self --ca --lifetime 3650 --in ~/pki/private/ca-key.pem \
    --type rsa --dn "CN=VPN root CA" --outform pem > ~/pki/cacerts/ca-cert.pem

ipsec pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/server-key.pem

ipsec pki --pub --in ~/pki/private/server-key.pem --type rsa \
    | ipsec pki --issue --lifetime 1825 \
        --cacert ~/pki/cacerts/ca-cert.pem \
        --cakey ~/pki/private/ca-key.pem \
        --dn "CN=$PUBLIC_IP" --san "$PUBLIC_IP" \
        --flag serverAuth --flag ikeIntermediate --outform pem \
    >  ~/pki/certs/server-cert.pem

cp -r ~/pki/* /etc/ipsec.d/



# Create IPsec config
#conf_bk "/etc/ipsec.conf"

if [[ -e "/etc/ipsec.conf" ]]; then

rm /etc/ipsec.conf

echo "Removed ipsec.conf existing file"

fi

cat >> /etc/ipsec.conf <<EOF
config setup
    charondebug="ike 1, knl 1, cfg 0"
    uniqueids=never

conn ikev2-vpn
    auto=add
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    dpdaction=clear
    dpddelay=300s
    rekey=no
    left=%any
    leftid=$PUBLIC_IP
    leftcert=server-cert.pem
    leftsendcert=always
    leftsubnet=0.0.0.0/0
    right=%any
    rightid=%any
    rightauth=eap-radius
    rightsourceip=10.10.10.0/24
    rightdns=8.8.8.8,8.8.4.4
    rightsendcert=never
    eap_identity=%any
    ike=aes256-sha1-modp1024,aes256gcm16-sha256-ecp521,aes256-sha256-ecp384,aes256-aes128-sha1-modp1024-3des!
    esp=aes256-sha1,aes128-sha256-modp3072,aes256gcm16-sha256,aes256gcm16-ecp384,aes256-sha256-sha1-3des!
EOF

if [[ -e "/etc/ipsec.secrets" ]]; then
rm /etc/ipsec.secrets
fi

 
cat >> /etc/ipsec.secrets <<EOF
: RSA "server-key.pem"
test : EAP "test123"

EOF

#conf "/etc/strongswan.conf"

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

# export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
# SYS_DT=$(date +%F-%T)

# exiterr()  { echo "Error: $1" >&2; exit 1; }
# exiterr2() { exiterr "'apt-get install' failed."; }
# conf_bk() { /bin/cp -f "$1" "$1.old-$SYS_DT" 2>/dev/null; }
# bigecho() { echo; echo "## $1"; echo; }

echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections

sudo apt-get -yq install iptables-persistent

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
iptables -t mangle -A FORWARD --match policy --pol ipsec --dir in -s 10.10.10.0/24 -o eth0 -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360
 
# masquerade VPN traffic over eth0 etc.
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o eth0 -m policy --pol ipsec --dir out -j ACCEPT  # exempt IPsec traffic from masquerading
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o eth0 -j MASQUERADE

# Saving Iptables rules
iptables-save > /etc/iptables/rules.v4


bigecho "Updating sysctl settings..."

if ! grep -qs "smarters VPN script" /etc/sysctl.conf; then
  conf_bk "/etc/sysctl.conf"


cat >> /etc/sysctl.conf <<EOF

# Added by smarters VPN script

net.ipv4.ip_forward = 1
net.ipv4.ip_no_pmtu_disc = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.disable_ipv6 = 1
EOF
fi

sysctl -p
ipsec restart
ca_cert=$(cat /etc/ipsec.d/cacerts/ca-cert.pem)
### ikev2 VPN server Installtion Done ###
if [ -z "$APIKEY" ]
       then

       echo "API Key Not Found! It seems the script runs directory on the server"

       else
     
       bigecho "Sending Server Status after installation succesfully"

       return_status=$(curl --data "api=$APIKEY&status=1&ip=$PUBLIC_IP&ca=$ca_cert" $PANELURL/includes/vpnapi/serverstatus.php);
       if [ "$return_status" == "1" ]; then
       echo "Return Status : "$return_status
       echo " Ack Done for Status Updation on Panel Side"
 else
       echo " Seems Server not updated on Panel Side"
       echo "Return Message: "$return_status
       fi
       fi

bigecho "Installion Done" 


bigecho " Username :  test"
bigecho " Password : test123"
bigecho " Certificate is " 

echo $ca_cert;

}

vpnremove()
{
apt remove strongswan strongswan-pki libcharon-standard-plugins libstrongswan libstrongswan-standard-plugins strongswan-charon strongswan-libcharon strongswan-starter -yq

# These package were automatically installed and no longer required : libcharon-standard-plugins libstrongswan libstrongswan-standard-plugins strongswan-charon strongswan-libcharon strongswan-starter
  
  # Removing Directories 
  
if [ -d "/root/pki/" ] 
then

    echo "Directory  exists." 
   
 rm -r /root/pki/  # need an improvement here 
fi
 
if [ -d "/etc/ipsec.d/" ] 

then 

  rm -r /etc/ipsec.d/

fi

if [[ -e /etc/ipsec.conf ]]; then

rm /etc/ipsec.conf

bigecho "Removed ipsec.conf existing file"

fi

if [[ -e /etc/ipsec.secrets ]]; then

rm /etc/ipsec.secrets

fi
bigecho "ikev2/ipsec removed succesfully"
}

  if [[ -z "$REMOVED" ]]; then
    vpnsetup "$@"
  else
    vpnremove "$@"
    vpnsetup "$@"
  fi
exit 0
