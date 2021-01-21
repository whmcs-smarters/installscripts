#!/bin/bash
#Created by WHMCS-Smarters Team. We provide VPN Software Solution & Services for Business at www.whmcssmarters.com

while getopts ":h:p:l:i:d:x:y:a:m:s:r:v:c:w:z:e:f:g:n:" o
do
    case "${o}" in
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
    c) REMOVED=${OPTARG}
    ;;
    g) LOGSTORE=${OPTARG}
    ;;
    n) CLIENTHOSTNAME=${OPTARG}
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
bigecho " VPN Installation Started ....."

if [ -z "$RADIUS_SECRET" ];then
  RADIUS_SECRET="testing123"
fi
# FOR STOPPING LOGS STORING
if [[ "$LOGSTORE" != "" ]]; then
  VERBVALUE=0
  LOGSTATUS='/dev/null'
  LOGSTATUSLINE='log /dev/null'
  else
  VERBVALUE=3
  LOGSTATUS='/var/log/openvpn/status.log'
  fi

#PUBLIC_IP=$(dig @resolver1.opendns.com -t A -4 myip.opendns.com +short)
#[ -z "$PUBLIC_IP" ] && PUBLIC_IP=$(wget -t 3 -T 15 -qO- http://ipv4.icanhazip.com)

PUBLIC_IP=$(curl ipinfo.io/ip)
OS="ubuntu"
echo " Public IP Address: $PUBLIC_IP"


vpnsetup() {
bigecho " Ikev2 VPN Installation Started..."
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
    rightdns=$DNS1,$DNS2
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

ETH0ORSIMILAR=$(ip route get 1.1.1.1 | awk -- '{printf $5}')
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
iptables -t mangle -A FORWARD --match policy --pol ipsec --dir in -s 10.10.10.0/24 -o $ETH0ORSIMILAR -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360
 
# masquerade VPN traffic over eth0 etc.
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o $ETH0ORSIMILAR -m policy --pol ipsec --dir out -j ACCEPT  # exempt IPsec traffic from masquerading
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o $ETH0ORSIMILAR -j MASQUERADE

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

bigecho " Username :  test"
bigecho " Password : test123"
bigecho " Certificate is "

echo $ca_cert;
bigecho "ikev2 VPN server Installtion Done"
}

vpnremove()
{
bigecho " Removing existing ikev2 VPN ..."
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


# check if it's root user
function isRoot () {
    if [ "$EUID" -ne 0 ]; then
        return 1
    fi
}
# tun/tap must be enabled
function tunAvailable () {
    if [ ! -e /dev/net/tun ]; then
        return 1
    fi
}

# we declared only Ubuntu must be installed with 18.04


function openvpnrestart()
{
bigecho " Restarting OpenVPN .."
# Finally, restart and enable OpenVPN
cp /lib/systemd/system/openvpn\@.service /etc/systemd/system/openvpn\@.service

# Workaround to fix OpenVPN service on OpenVZ
sed -i 's|LimitNPROC|#LimitNPROC|' /etc/systemd/system/openvpn\@.service
# Another workaround to keep using /etc/openvpn/
sed -i 's|/etc/openvpn/server|/etc/openvpn|' /etc/systemd/system/openvpn\@.service

systemctl daemon-reload
systemctl restart openvpn@server
systemctl enable openvpn@server

}
function installUnbound () {
    if [[ ! -e /etc/unbound/unbound.conf ]]; then

        if [[ "$OS" =~ (debian|ubuntu) ]]; then
            apt-get install -y unbound

            # Configuration
            echo 'interface: 10.8.0.1
access-control: 10.8.0.1/24 allow
hide-identity: yes
hide-version: yes
use-caps-for-id: yes
prefetch: yes' >> /etc/unbound/unbound.conf

        elif [[ "$OS" =~ (centos|amzn) ]]; then
            yum install -y unbound

            # Configuration
            sed -i 's|# interface: 0.0.0.0$|interface: 10.8.0.1|' /etc/unbound/unbound.conf
            sed -i 's|# access-control: 127.0.0.0/8 allow|access-control: 10.8.0.1/24 allow|' /etc/unbound/unbound.conf
            sed -i 's|# hide-identity: no|hide-identity: yes|' /etc/unbound/unbound.conf
            sed -i 's|# hide-version: no|hide-version: yes|' /etc/unbound/unbound.conf
            sed -i 's|use-caps-for-id: no|use-caps-for-id: yes|' /etc/unbound/unbound.conf

        elif [[ "$OS" = "fedora" ]]; then
            dnf install -y unbound

            # Configuration
            sed -i 's|# interface: 0.0.0.0$|interface: 10.8.0.1|' /etc/unbound/unbound.conf
            sed -i 's|# access-control: 127.0.0.0/8 allow|access-control: 10.8.0.1/24 allow|' /etc/unbound/unbound.conf
            sed -i 's|# hide-identity: no|hide-identity: yes|' /etc/unbound/unbound.conf
            sed -i 's|# hide-version: no|hide-version: yes|' /etc/unbound/unbound.conf
            sed -i 's|# use-caps-for-id: no|use-caps-for-id: yes|' /etc/unbound/unbound.conf

        elif [[ "$OS" = "arch" ]]; then
            pacman -Syu --noconfirm unbound

            # Get root servers list
            curl -o /etc/unbound/root.hints https://www.internic.net/domain/named.cache

            mv /etc/unbound/unbound.conf /etc/unbound/unbound.conf.old

            echo 'server:
    use-syslog: yes
    do-daemonize: no
    username: "unbound"
    directory: "/etc/unbound"
    trust-anchor-file: trusted-key.key
    root-hints: root.hints
    interface: 10.8.0.1
    access-control: 10.8.0.1/24 allow
    port: 53
    num-threads: 2
    use-caps-for-id: yes
    harden-glue: yes
    hide-identity: yes
    hide-version: yes
    qname-minimisation: yes
    prefetch: yes' > /etc/unbound/unbound.conf
        fi

        if [[ ! "$OS" =~ (fedora|centos|amzn) ]];then
            # DNS Rebinding fix
            echo "private-address: 10.0.0.0/8
private-address: 172.16.0.0/12
private-address: 192.168.0.0/16
private-address: 169.254.0.0/16
private-address: fd00::/8
private-address: fe80::/10
private-address: 127.0.0.0/8
private-address: ::ffff:0:0/96" >> /etc/unbound/unbound.conf
        fi
    else # Unbound is already installed
        echo 'include: /etc/unbound/openvpn.conf' >> /etc/unbound/unbound.conf

        # Add Unbound 'server' for the OpenVPN subnet
        echo 'server:
interface: 10.8.0.1
access-control: 10.8.0.1/24 allow
hide-identity: yes
hide-version: yes
use-caps-for-id: yes
prefetch: yes
private-address: 10.0.0.0/8
private-address: 172.16.0.0/12
private-address: 192.168.0.0/16
private-address: 169.254.0.0/16
private-address: fd00::/8
private-address: fe80::/10
private-address: 127.0.0.0/8
private-address: ::ffff:0:0/96' > /etc/unbound/openvpn.conf
    fi

        systemctl enable unbound
        systemctl restart unbound
}

function installQuestions () {

    echo "Welcome to the OpenVPN installer!"
    
    # Detect public IPv4 address and pre-fill for the user
    IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
    APPROVE_IP=${APPROVE_IP:-n}
    if [[ $APPROVE_IP =~ n ]]; then
        read -rp "IP address: " -e -i "$IP" IP
    fi
    #Â If $IP is a private IP address, the server must be behind NAT
    if echo "$IP" | grep -qE '^(10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|192\.168)'; then
        echo ""
        echo "It seems this server is behind NAT. What is its public IPv4 address or hostname?"
        echo "We need it for the clients to connect to the server."
        until [[ "$ENDPOINT" != "" ]]; do
            read -rp "Public IPv4 address or hostname: " -e ENDPOINT
        done
    fi

    echo ""
    echo "Checking for IPv6 connectivity..."
    echo ""
    # "ping6" and "ping -6" availability varies depending on the distribution
    if type ping6 > /dev/null 2>&1; then
        PING6="ping6 -c3 ipv6.google.com > /dev/null 2>&1"
    else
        PING6="ping -6 -c3 ipv6.google.com > /dev/null 2>&1"
    fi
    if eval "$PING6"; then
        echo "Your host appears to have IPv6 connectivity."
        SUGGESTION="y"
    else
        echo "Your host does not appear to have IPv6 connectivity."
        SUGGESTION="n"
        IPV6_SUPPORT="n"
    fi
    echo ""
   
   if [ -z "$PORT" ]
      then
      PORT=1194
      echo " set default port 1194"
      else
       echo "Custom Port Defined by User $PORT"
      fi
   if [ -z "$PROTOCOL" ]
       then
       echo " Protcol is not customised let's set is to UDP";
       
         PROTOCOL="udp"
       fi
   if [ -z "$DNS" ]
      then
      echo " DNS is not set by client,we will use the default (CloudFlare DNS) "
      DNS=3
      fi

  #  until [[ "$DNS" =~ ^[0-9]+$ ]] && [ "$DNS" -ge 1 ] && [ "$DNS" -le 12 ]; do
        #read -rp "DNS [1-12]: " -e -i 3 DNS
            if [[ $DNS == 2 ]] && [[ -e /etc/unbound/unbound.conf ]]; then
                echo ""
                echo "Unbound is already installed."
                echo "You can allow the script to configure it in order to use it from your OpenVPN clients"
                echo "We will simply add a second server to /etc/unbound/unbound.conf for the OpenVPN subnet."
                echo "No changes are made to the current configuration."
                echo ""

                until [[ $CONTINUE =~ (y|n) ]]; do
                    read -rp "Apply configuration changes to Unbound? [y/n]: " -e CONTINUE
                done
                if [[ $CONTINUE = "n" ]];then
                    # Break the loop and cleanup
                    unset DNS
                    unset CONTINUE
                fi
            elif [[ $DNS == "12" ]]; then
            
              
                    if [[ "$DNS2" == "" ]]; then
                        break
                    fi
               # done
            fi
   # done
    echo ""
    echo "Do you want to use compression? It is not recommended since the VORACLE attack make use of it."
    until [[ $COMPRESSION_ENABLED =~ (y|n) ]]; do
        read -rp"Enable compression? [y/n]: " -e -i n COMPRESSION_ENABLED
    done
    if [[ $COMPRESSION_ENABLED == "y" ]];then
        echo "Choose which compression algorithm you want to use: (they are ordered by efficiency)"
        echo "   1) LZ4-v2"
        echo "   2) LZ4"
        echo "   3) LZ0"
        until [[ $COMPRESSION_CHOICE =~ ^[1-3]$ ]]; do
            read -rp"Compression algorithm [1-3]: " -e -i 1 COMPRESSION_CHOICE
        done
        case $COMPRESSION_CHOICE in
            1)
            COMPRESSION_ALG="lz4-v2"
            ;;
            2)
            COMPRESSION_ALG="lz4"
            ;;
            3)
            COMPRESSION_ALG="lzo"
            ;;
        esac
    fi
    echo ""
     
    until [[ $CUSTOMIZE_ENC =~ (y|n) ]]; do
        read -rp "Customize encryption settings? [y/n]: " -e -i n CUSTOMIZE_ENC
    done
    if [[ $CUSTOMIZE_ENC == "n" ]];then
        # Use default, sane and fast parameters
        CIPHER="AES-128-GCM"
        CERT_TYPE="1" # ECDSA
        CERT_CURVE="prime256v1"
        CC_CIPHER="TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256"
        DH_TYPE="1" # ECDH
        DH_CURVE="prime256v1"
        HMAC_ALG="SHA256"
        TLS_SIG="1" # tls-crypt
    else
        echo ""
        
        until [[ "$CIPHER_CHOICE" =~ ^[1-6]$ ]]; do
            read -rp "Cipher [1-6]: " -e -i 1 CIPHER_CHOICE
        done
        case $CIPHER_CHOICE in
            1)
                CIPHER="AES-128-GCM"
            ;;
            2)
                CIPHER="AES-192-GCM"
            ;;
            3)
                CIPHER="AES-256-GCM"
            ;;
            4)
                CIPHER="AES-128-CBC"
            ;;
            5)
                CIPHER="AES-192-CBC"
            ;;
            6)
                CIPHER="AES-256-CBC"
            ;;
        esac
        echo ""
        echo "Choose what kind of certificate you want to use:"
        echo "   1) ECDSA (recommended)"
        echo "   2) RSA"
        until [[ $CERT_TYPE =~ ^[1-2]$ ]]; do
            read -rp"Certificate key type [1-2]: " -e -i 1 CERT_TYPE
        done
        case $CERT_TYPE in
            1)
                echo ""
                echo "Choose which curve you want to use for the certificate's key:"
                echo "   1) prime256v1 (recommended)"
                echo "   2) secp384r1"
                echo "   3) secp521r1"
                until [[ $CERT_CURVE_CHOICE =~ ^[1-3]$ ]]; do
                    read -rp"Curve [1-3]: " -e -i 1 CERT_CURVE_CHOICE
                done
                case $CERT_CURVE_CHOICE in
                    1)
                        CERT_CURVE="prime256v1"
                    ;;
                    2)
                        CERT_CURVE="secp384r1"
                    ;;
                    3)
                        CERT_CURVE="secp521r1"
                    ;;
                esac
            ;;
            2)
                echo ""
                echo "Choose which size you want to use for the certificate's RSA key:"
                echo "   1) 2048 bits (recommended)"
                echo "   2) 3072 bits"
                echo "   3) 4096 bits"
                until [[ "$RSA_KEY_SIZE_CHOICE" =~ ^[1-3]$ ]]; do
                    read -rp "RSA key size [1-3]: " -e -i 1 RSA_KEY_SIZE_CHOICE
                done
                case $RSA_KEY_SIZE_CHOICE in
                    1)
                        RSA_KEY_SIZE="2048"
                    ;;
                    2)
                        RSA_KEY_SIZE="3072"
                    ;;
                    3)
                        RSA_KEY_SIZE="4096"
                    ;;
                esac
            ;;
        esac
        echo ""
        echo "Choose which cipher you want to use for the control channel:"
        case $CERT_TYPE in
            1)
                echo "   1) ECDHE-ECDSA-AES-128-GCM-SHA256 (recommended)"
                echo "   2) ECDHE-ECDSA-AES-256-GCM-SHA384"
                until [[ $CC_CIPHER_CHOICE =~ ^[1-2]$ ]]; do
                    read -rp"Control channel cipher [1-2]: " -e -i 1 CC_CIPHER_CHOICE
                done
                case $CC_CIPHER_CHOICE in
                    1)
                        CC_CIPHER="TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256"
                    ;;
                    2)
                        CC_CIPHER="TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384"
                    ;;
                esac
            ;;
            2)
                echo "   1) ECDHE-RSA-AES-128-GCM-SHA256 (recommended)"
                echo "   2) ECDHE-RSA-AES-256-GCM-SHA384"
                until [[ $CC_CIPHER_CHOICE =~ ^[1-2]$ ]]; do
                    read -rp"Control channel cipher [1-2]: " -e -i 1 CC_CIPHER_CHOICE
                done
                case $CC_CIPHER_CHOICE in
                    1)
                        CC_CIPHER="TLS-ECDHE-RSA-WITH-AES-128-GCM-SHA256"
                    ;;
                    2)
                        CC_CIPHER="TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384"
                    ;;
                esac
            ;;
        esac
        echo ""
        echo "Choose what kind of Diffie-Hellman key you want to use:"
        echo "   1) ECDH (recommended)"
        echo "   2) DH"
        until [[ $DH_TYPE =~ [1-2] ]]; do
            read -rp"DH key type [1-2]: " -e -i 1 DH_TYPE
        done
        case $DH_TYPE in
            1)
                echo ""
                echo "Choose which curve you want to use for the ECDH key:"
                echo "   1) prime256v1 (recommended)"
                echo "   2) secp384r1"
                echo "   3) secp521r1"
                while [[ $DH_CURVE_CHOICE != "1" && $DH_CURVE_CHOICE != "2" && $DH_CURVE_CHOICE != "3" ]]; do
                    read -rp"Curve [1-3]: " -e -i 1 DH_CURVE_CHOICE
                done
                case $DH_CURVE_CHOICE in
                    1)
                        DH_CURVE="prime256v1"
                    ;;
                    2)
                        DH_CURVE="secp384r1"
                    ;;
                    3)
                        DH_CURVE="secp521r1"
                    ;;
                esac
            ;;
            2)
                echo ""
                echo "Choose what size of Diffie-Hellman key you want to use:"
                echo "   1) 2048 bits (recommended)"
                echo "   2) 3072 bits"
                echo "   3) 4096 bits"
                until [[ "$DH_KEY_SIZE_CHOICE" =~ ^[1-3]$ ]]; do
                    read -rp "DH key size [1-3]: " -e -i 1 DH_KEY_SIZE_CHOICE
                done
                case $DH_KEY_SIZE_CHOICE in
                    1)
                        DH_KEY_SIZE="2048"
                    ;;
                    2)
                        DH_KEY_SIZE="3072"
                    ;;
                    3)
                        DH_KEY_SIZE="4096"
                    ;;
                esac
            ;;
        esac
        echo ""
        # The "auth" options behaves differently with AEAD ciphers
        if [[ "$CIPHER" =~ CBC$ ]]; then
            echo "The digest algorithm authenticates data channel packets and tls-auth packets from the control channel."
        elif [[ "$CIPHER" =~ GCM$ ]]; then
            echo "The digest algorithm authenticates tls-auth packets from the control channel."
        fi
        echo "Which digest algorithm do you want to use for HMAC?"
        echo "   1) SHA-256 (recommended)"
        echo "   2) SHA-384"
        echo "   3) SHA-512"
        until [[ $HMAC_ALG_CHOICE =~ ^[1-3]$ ]]; do
            read -rp "Digest algorithm [1-3]: " -e -i 1 HMAC_ALG_CHOICE
        done
        case $HMAC_ALG_CHOICE in
            1)
                HMAC_ALG="SHA256"
            ;;
            2)
                HMAC_ALG="SHA384"
            ;;
            3)
                HMAC_ALG="SHA512"
            ;;
        esac
        echo ""
        echo "You can add an additional layer of security to the control channel with tls-auth and tls-crypt"
        echo "tls-auth authenticates the packets, while tls-crypt authenticate and encrypt them."
        echo "   1) tls-crypt (recommended)"
        echo "   2) tls-auth"
        until [[ $TLS_SIG =~ [1-2] ]]; do
                read -rp "Control channel additional security mechanism [1-2]: " -e -i 1 TLS_SIG
        done
    fi
    echo ""
    echo "Okay, that was all I needed. We are ready to setup your OpenVPN server now."
    echo "You will be able to generate a client at the end of the installation."
    APPROVE_INSTALL=${APPROVE_INSTALL:-n}
    if [[ $APPROVE_INSTALL =~ n ]]; then
        read -n1 -r -p "Press any key to continue..."
    fi
}

function installOpenVPN () {
    
        APPROVE_INSTALL=${APPROVE_INSTALL:-y}
        APPROVE_IP=${APPROVE_IP:-y}
        IPV6_SUPPORT=${IPV6_SUPPORT:-n}
        PORT_CHOICE=${PORT_CHOICE:-1}
        PROTOCOL_CHOICE=${PROTOCOL_CHOICE:-1}
        DNS=${DNS:-1}
        COMPRESSION_ENABLED=${COMPRESSION_ENABLED:-n}
        CUSTOMIZE_ENC=${CUSTOMIZE_ENC:-n}
        CLIENT=${CLIENT:-client}
        PASS=${PASS:-1}
        CONTINUE=${CONTINUE:-y}

        # Behind NAT, we'll default to the publicly reachable IPv4.
       # PUBLIC_IPV4=$(curl ifconfig.co)
        PUBLIC_IPV4=$(curl ipinfo.io/ip)
        ENDPOINT=${ENDPOINT:-$PUBLIC_IPV4}
   

    # Run setup questions first, and set other variales if auto-install
    installQuestions

    # Get the "public" interface from the default route
    NIC=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

    if [[ "$OS" =~ (debian|ubuntu) ]]; then
        apt-get update
        apt-get -y install ca-certificates gnupg
        # We add the OpenVPN repo to get the latest version.
        if [[ "$VERSION_ID" = "8" ]]; then
            echo "deb http://build.openvpn.net/debian/openvpn/stable jessie main" > /etc/apt/sources.list.d/openvpn.list
            wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add -
            apt-get update
        fi
        if [[ "$VERSION_ID" = "16.04" ]]; then
            echo "deb http://build.openvpn.net/debian/openvpn/stable xenial main" > /etc/apt/sources.list.d/openvpn.list
            wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add -
            apt-get update
        fi
        # Ubuntu > 16.04 and Debian > 8 have OpenVPN >= 2.4 without the need of a third party repository.
        apt-get install -y openvpn iptables openssl wget ca-certificates curl
    elif [[ "$OS" = 'centos' ]]; then
        yum install -y epel-release
        yum install -y openvpn iptables openssl wget ca-certificates curl tar
    elif [[ "$OS" = 'amzn' ]]; then
        amazon-linux-extras install -y epel
        yum install -y openvpn iptables openssl wget ca-certificates curl
    elif [[ "$OS" = 'fedora' ]]; then
        dnf install -y openvpn iptables openssl wget ca-certificates curl
    elif [[ "$OS" = 'arch' ]]; then
        # Install required dependencies and upgrade the system
        pacman --needed --noconfirm -Syu openvpn iptables openssl wget ca-certificates curl
    fi

    # Find out if the machine uses nogroup or nobody for the permissionless group
    if grep -qs "^nogroup:" /etc/group; then
        NOGROUP=nogroup
    else
        NOGROUP=nobody
    fi

    # An old version of easy-rsa was available by default in some openvpn packages
    if [[ -d /etc/openvpn/easy-rsa/ ]]; then
        rm -rf /etc/openvpn/easy-rsa/
    fi

    # Install the latest version of easy-rsa from source
    local version="3.0.6"
    wget -O ~/EasyRSA-unix-v${version}.tgz https://github.com/OpenVPN/easy-rsa/releases/download/v${version}/EasyRSA-unix-v${version}.tgz
    tar xzf ~/EasyRSA-unix-v${version}.tgz -C ~/
    mv ~/EasyRSA-v${version} /etc/openvpn/easy-rsa
    chown -R root:root /etc/openvpn/easy-rsa/
    rm -f ~/EasyRSA-unix-v${version}.tgz

    cd /etc/openvpn/easy-rsa/ || return
    case $CERT_TYPE in
        1)
            echo "set_var EASYRSA_ALGO ec" > vars
            echo "set_var EASYRSA_CURVE $CERT_CURVE" >> vars
        ;;
        2)
            echo "set_var EASYRSA_KEY_SIZE $RSA_KEY_SIZE" > vars
        ;;
    esac

    # Generate a random, alphanumeric identifier of 16 characters for CN and one for server name
    SERVER_CN="cn_$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)"
    SERVER_NAME="server_$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)"
    echo "set_var EASYRSA_REQ_CN $SERVER_CN" >> vars

    # Create the PKI, set up the CA, the DH params and the server certificate
    ./easyrsa init-pki

        # Workaround to remove unharmful error until easy-rsa 3.0.7
        # https://github.com/OpenVPN/easy-rsa/issues/261
        sed -i 's/^RANDFILE/#RANDFILE/g' pki/openssl-easyrsa.cnf

    ./easyrsa --batch build-ca nopass

    if [[ $DH_TYPE == "2" ]]; then
        # ECDH keys are generated on-the-fly so we don't need to generate them beforehand
        openssl dhparam -out dh.pem $DH_KEY_SIZE
    fi

    ./easyrsa build-server-full "$SERVER_NAME" nopass
    EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl

    case $TLS_SIG in
        1)
            # Generate tls-crypt key
            openvpn --genkey --secret /etc/openvpn/tls-crypt.key
        ;;
        2)
            # Generate tls-auth key
            openvpn --genkey --secret /etc/openvpn/tls-auth.key
        ;;
    esac

    # Move all the generated files
    cp pki/ca.crt pki/private/ca.key "pki/issued/$SERVER_NAME.crt" "pki/private/$SERVER_NAME.key" /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn
    if [[ $DH_TYPE == "2" ]]; then
        cp dh.pem /etc/openvpn
    fi

    # Make cert revocation list readable for non-root
    chmod 644 /etc/openvpn/crl.pem

    # Generate server.conf
   
    echo "port $PORT" > /etc/openvpn/server.conf
    if [[ "$IPV6_SUPPORT" = 'n' ]]; then
        echo "proto $PROTOCOL" >> /etc/openvpn/server.conf
    elif [[ "$IPV6_SUPPORT" = 'y' ]]; then
        echo "proto ${PROTOCOL}6" >> /etc/openvpn/server.conf
    fi

echo "dev tun
user nobody
group $NOGROUP
persist-key
persist-tun
keepalive 10 120
reneg-sec 0
topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt" >> /etc/openvpn/server.conf

    # DNS resolvers
    
    case $DNS in
        1)
            # Locate the proper resolv.conf
            # Needed for systems running systemd-resolved
            if grep -q "127.0.0.53" "/etc/resolv.conf"; then
                RESOLVCONF='/run/systemd/resolve/resolv.conf'
            else
                RESOLVCONF='/etc/resolv.conf'
            fi
            # Obtain the resolvers from resolv.conf and use them for OpenVPN
            grep -v '#' $RESOLVCONF | grep 'nameserver' | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | while read -r line; do
                echo "push \"dhcp-option DNS $line\"" >> /etc/openvpn/server.conf
            done
        ;;
        2)
            echo 'push "dhcp-option DNS 10.8.0.1"' >> /etc/openvpn/server.conf
        ;;
        3) # Cloudflare
            echo 'push "dhcp-option DNS 1.0.0.1"' >> /etc/openvpn/server.conf
            echo 'push "dhcp-option DNS 1.1.1.1"' >> /etc/openvpn/server.conf
        ;;
        4) # Quad9
            echo 'push "dhcp-option DNS 9.9.9.9"' >> /etc/openvpn/server.conf
            echo 'push "dhcp-option DNS 149.112.112.112"' >> /etc/openvpn/server.conf
        ;;
        5) # Quad9 uncensored
            echo 'push "dhcp-option DNS 9.9.9.10"' >> /etc/openvpn/server.conf
            echo 'push "dhcp-option DNS 149.112.112.10"' >> /etc/openvpn/server.conf
        ;;
        6) # FDN
            echo 'push "dhcp-option DNS 80.67.169.40"' >> /etc/openvpn/server.conf
            echo 'push "dhcp-option DNS 80.67.169.12"' >> /etc/openvpn/server.conf
        ;;
        7) # DNS.WATCH
            echo 'push "dhcp-option DNS 84.200.69.80"' >> /etc/openvpn/server.conf
            echo 'push "dhcp-option DNS 84.200.70.40"' >> /etc/openvpn/server.conf
        ;;
        8) # OpenDNS
            echo 'push "dhcp-option DNS 208.67.222.222"' >> /etc/openvpn/server.conf
            echo 'push "dhcp-option DNS 208.67.220.220"' >> /etc/openvpn/server.conf
        ;;
        9) # Google
            echo 'push "dhcp-option DNS 8.8.8.8"' >> /etc/openvpn/server.conf
            echo 'push "dhcp-option DNS 8.8.4.4"' >> /etc/openvpn/server.conf
        ;;
        10) # Yandex Basic
            echo 'push "dhcp-option DNS 77.88.8.8"' >> /etc/openvpn/server.conf
            echo 'push "dhcp-option DNS 77.88.8.1"' >> /etc/openvpn/server.conf
        ;;
        11) # AdGuard DNS
            echo 'push "dhcp-option DNS 176.103.130.130"' >> /etc/openvpn/server.conf
            echo 'push "dhcp-option DNS 176.103.130.131"' >> /etc/openvpn/server.conf
        ;;
        12) # Custom DNS
        echo "push \"dhcp-option DNS $DNS1\"" >> /etc/openvpn/server.conf
        if [[ "$DNS2" != "" ]]; then
            echo "push \"dhcp-option DNS $DNS2\"" >> /etc/openvpn/server.conf
        fi
        ;;
    esac
    echo 'push "redirect-gateway def1 bypass-dhcp"' >> /etc/openvpn/server.conf

    # IPv6 network settings if needed
    if [[ "$IPV6_SUPPORT" = 'y' ]]; then
        echo 'server-ipv6 fd42:42:42:42::/112
tun-ipv6
push tun-ipv6
push "route-ipv6 2000::/3"
push "redirect-gateway ipv6"' >> /etc/openvpn/server.conf
    fi

    if [[ $COMPRESSION_ENABLED == "y"  ]]; then
        echo "compress $COMPRESSION_ALG" >> /etc/openvpn/server.conf
    fi

    if [[ $DH_TYPE == "1" ]]; then
        echo "dh none" >> /etc/openvpn/server.conf
        echo "ecdh-curve $DH_CURVE" >> /etc/openvpn/server.conf
    elif [[ $DH_TYPE == "2" ]]; then
        echo "dh dh.pem" >> /etc/openvpn/server.conf
    fi

    case $TLS_SIG in
        1)
            echo "tls-crypt tls-crypt.key 0" >> /etc/openvpn/server.conf
        ;;
        2)
            echo "tls-auth tls-auth.key 0" >> /etc/openvpn/server.conf
        ;;
    esac

    echo "crl-verify crl.pem
ca ca.crt
cert $SERVER_NAME.crt
key $SERVER_NAME.key
auth $HMAC_ALG
script-security 2
duplicate-cn
cipher $CIPHER
ncp-ciphers $CIPHER
tls-server
tls-version-min 1.2
tls-cipher $CC_CIPHER
$LOGSTATUSLINE
status $LOGSTATUS
plugin /etc/openvpn/radius/radiusplugin.so /etc/openvpn/radius/radius.cnf ifconfig-pool-persist ipp.txt persist-key
verb $VERBVALUE" >> /etc/openvpn/server.conf

    # Create log dir
    mkdir -p /var/log/openvpn

    # Enable routing
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.d/20-openvpn.conf
    if [[ "$IPV6_SUPPORT" = 'y' ]]; then
        echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.d/20-openvpn.conf
    fi
    # Apply sysctl rules
    sysctl --system

    # If SELinux is enabled and a custom port was selected, we need this
    if hash sestatus 2>/dev/null; then
        if sestatus | grep "Current mode" | grep -qs "enforcing"; then
            if [[ "$PORT" != '1194' ]]; then
                semanage port -a -t openvpn_port_t -p "$PROTOCOL" "$PORT"
            fi
        fi
    fi

    if [[ $DNS == 2 ]];then
        installUnbound
    fi

    # Add iptables rules in two scripts
    mkdir /etc/iptables

    # Script to add rules
    echo "#!/bin/sh
iptables -t nat -I POSTROUTING 1 -s 10.8.0.0/24 -o $NIC -j MASQUERADE
iptables -I INPUT 1 -i tun0 -j ACCEPT
iptables -I FORWARD 1 -i $NIC -o tun0 -j ACCEPT
iptables -I FORWARD 1 -i tun0 -o $NIC -j ACCEPT
iptables -I INPUT 1 -i $NIC -p $PROTOCOL --dport $PORT -j ACCEPT" > /etc/iptables/add-openvpn-rules.sh

    if [[ "$IPV6_SUPPORT" = 'y' ]]; then
        echo "ip6tables -t nat -I POSTROUTING 1 -s fd42:42:42:42::/112 -o $NIC -j MASQUERADE
ip6tables -I INPUT 1 -i tun0 -j ACCEPT
ip6tables -I FORWARD 1 -i $NIC -o tun0 -j ACCEPT
ip6tables -I FORWARD 1 -i tun0 -o $NIC -j ACCEPT" >> /etc/iptables/add-openvpn-rules.sh
    fi

    # Script to remove rules
    echo "#!/bin/sh
iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o $NIC -j MASQUERADE
iptables -D INPUT -i tun0 -j ACCEPT
iptables -D FORWARD -i $NIC -o tun0 -j ACCEPT
iptables -D FORWARD -i tun0 -o $NIC -j ACCEPT
iptables -D INPUT -i $NIC -p $PROTOCOL --dport $PORT -j ACCEPT" > /etc/iptables/rm-openvpn-rules.sh

    if [[ "$IPV6_SUPPORT" = 'y' ]]; then
        echo "ip6tables -t nat -D POSTROUTING -s fd42:42:42:42::/112 -o $NIC -j MASQUERADE
ip6tables -D INPUT -i tun0 -j ACCEPT
ip6tables -D FORWARD -i $NIC -o tun0 -j ACCEPT
ip6tables -D FORWARD -i tun0 -o $NIC -j ACCEPT" >> /etc/iptables/rm-openvpn-rules.sh
    fi

    chmod +x /etc/iptables/add-openvpn-rules.sh
    chmod +x /etc/iptables/rm-openvpn-rules.sh

    # Handle the rules via a systemd script
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

    # Enable service and apply rules
    systemctl daemon-reload
    systemctl enable iptables-openvpn
    systemctl start iptables-openvpn

    # If the server is behind a NAT, use the correct IP address for the clients to connect to
    if [[ "$ENDPOINT" != "" ]]; then
        IP=$ENDPOINT
    fi

    # client-template.txt is created so we have a template to add further users later
    echo "client" > /etc/openvpn/client-template.txt
    if [[ "$PROTOCOL" = 'udp' ]]; then
        echo "proto udp" >> /etc/openvpn/client-template.txt
    elif [[ "$PROTOCOL" = 'tcp' ]]; then
        echo "proto tcp-client" >> /etc/openvpn/client-template.txt
    fi
  
 
    echo "remote $IP $PORT
dev tun
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verify-x509-name $SERVER_NAME name
auth $HMAC_ALG
auth-nocache
auth-user-pass
cipher $CIPHER
tls-client
tls-version-min 1.2
tls-cipher $CC_CIPHER
explicit-exit-notify 2

verb $VERBVALUE" >> /etc/openvpn/client-template.txt
# Setting HTTP Proxy ( it must be worked with TCP proto)
  if [[ "$PROXYSERVER" != "" ]]; then
        echo "http-proxy $PROXYSERVER $PROXYPORT" >> /etc/openvpn/client-template.txt
  fi
  if [[ "$PROXYRETRY" == 'on' ]]; then
    echo "http-proxy-retry" >> /etc/openvpn/client-template.txt
  fi
  if [[ "$CUSTOMHEADER" != '' ]]; then
    echo -e "$CUSTOMHEADER" >> /etc/openvpn/client-template.txt
  fi

  
  # if [[ "$PROXYHEADER" != "" ]]; then
  #       echo "http-proxy-option CUSTOM-HEADER X-Online-Host m.tim.it/extra-internet" >> /etc/openvpn/client-template.txt
  #       echo "http-proxy-option CUSTOM-HEADER Host m.tim.it/extra-internet" >> /etc/openvpn/client-template.txt
  # fi
if [[ $COMPRESSION_ENABLED == "y"  ]]; then
    echo "compress $COMPRESSION_ALG" >> /etc/openvpn/client-template.txt
fi

    # Generate the custom client.ovpn
    newClient
 #exit 0
}
function newClient () {
    echo ""
    echo "Tell me a name for the client."
    echo "Use one word only, no special characters."

    until [[ "$CLIENT" =~ ^[a-zA-Z0-9_]+$ ]]; do
        read -rp "Client name: " -e CLIENT
    done

    echo ""
    echo "Do you want to protect the configuration file with a password?"
    echo "(e.g. encrypt the private key with a password)"
    echo "   1) Add a passwordless client"
    echo "   2) Use a password for the client"

    until [[ "$PASS" =~ ^[1-2]$ ]]; do
        read -rp "Select an option [1-2]: " -e -i 1 PASS
    done

    cd /etc/openvpn/easy-rsa/ || return
    case $PASS in
        1)
            ./easyrsa build-client-full "$CLIENT" nopass
        ;;
        2)
        echo "âš ï¸�? You will be asked for the client password below âš ï¸�?"
            ./easyrsa build-client-full "$CLIENT"
        ;;
    esac

    # Home directory of the user, where the client configuration (.ovpn) will be written
    if [ -e "/home/$CLIENT" ]; then  # if $1 is a user name
        homeDir="/home/$CLIENT"
    elif [ "${SUDO_USER}" ]; then # if not, use SUDO_USER
        homeDir="/home/${SUDO_USER}"
    else # if not SUDO_USER, use /root
        homeDir="/root"
    fi

    # Determine if we use tls-auth or tls-crypt
    if grep -qs "^tls-crypt" /etc/openvpn/server.conf; then
        TLS_SIG="1"
    elif grep -qs "^tls-auth" /etc/openvpn/server.conf; then
        TLS_SIG="2"
    fi

    # Generates the custom client.ovpn
    cp /etc/openvpn/client-template.txt "$homeDir/$CLIENT.ovpn"
    {
        echo "<ca>"
        cat "/etc/openvpn/easy-rsa/pki/ca.crt"
        echo "</ca>"

        echo "<cert>"
        awk '/BEGIN/,/END/' "/etc/openvpn/easy-rsa/pki/issued/$CLIENT.crt"
        echo "</cert>"

        echo "<key>"
        cat "/etc/openvpn/easy-rsa/pki/private/$CLIENT.key"
        echo "</key>"

        case $TLS_SIG in
            1)
                echo "<tls-crypt>"
                cat /etc/openvpn/tls-crypt.key
                echo "</tls-crypt>"
            ;;
            2)
                echo "key-direction 1"
                echo "<tls-auth>"
                cat /etc/openvpn/tls-auth.key
                echo "</tls-auth>"
            ;;
        esac
    } >> "$homeDir/$CLIENT.ovpn"


    echo ""
    echo "Client $CLIENT added, the configuration file is available at $homeDir/$CLIENT.ovpn."
    
    echo "Download the .ovpn file and import it in your OpenVPN client."
    
}

function revokeClient () {
    NUMBEROFCLIENTS=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c "^V")
    if [[ "$NUMBEROFCLIENTS" = '0' ]]; then
        echo ""
        echo "You have no existing clients!"
        exit 1
    fi

    echo ""
    echo "Select the existing client certificate you want to revoke"
    tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | nl -s ') '
    if [[ "$NUMBEROFCLIENTS" = '1' ]]; then
        read -rp "Select one client [1]: " CLIENTNUMBER
    else
        read -rp "Select one client [1-$NUMBEROFCLIENTS]: " CLIENTNUMBER
    fi

    CLIENT=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | sed -n "$CLIENTNUMBER"p)
    cd /etc/openvpn/easy-rsa/ || return
    ./easyrsa --batch revoke "$CLIENT"
    EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
    # Cleanup
    rm -f "pki/reqs/$CLIENT.req"
    rm -f "pki/private/$CLIENT.key"
    rm -f "pki/issued/$CLIENT.crt"
    rm -f /etc/openvpn/crl.pem
    cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
    chmod 644 /etc/openvpn/crl.pem
    find /home/ -maxdepth 2 -name "$CLIENT.ovpn" -delete
    rm -f "/root/$CLIENT.ovpn"
    sed -i "s|^$CLIENT,.*||" /etc/openvpn/ipp.txt

    echo ""
    echo "Certificate for client $CLIENT revoked."
}

function removeUnbound () {
    # Remove OpenVPN-related config
    sed -i 's|include: \/etc\/unbound\/openvpn.conf||' /etc/unbound/unbound.conf
    rm /etc/unbound/openvpn.conf
    systemctl restart unbound

    until [[ $REMOVE_UNBOUND =~ (y|n) ]]; do
        echo ""
        echo "If you were already using Unbound before installing OpenVPN, I removed the configuration related to OpenVPN."
        read -rp "Do you want to completely remove Unbound? [y/n]: " -e REMOVE_UNBOUND
    done

    if [[ "$REMOVE_UNBOUND" = 'y' ]]; then
        # Stop Unbound
        systemctl stop unbound

        if [[ "$OS" =~ (debian|ubuntu) ]]; then
            apt-get autoremove --purge -y unbound
        elif [[ "$OS" = 'arch' ]]; then
            pacman --noconfirm -R unbound
        elif [[ "$OS" =~ (centos|amzn) ]]; then
            yum remove -y unbound
        elif [[ "$OS" = 'fedora' ]]; then
            dnf remove -y unbound
        fi

        rm -rf /etc/unbound/

        echo ""
        echo "Unbound removed!"
    else
        echo ""
        echo "Unbound wasn't removed."
    fi
}

function removeOpenVPN () {
    bigecho " Removing existing OpenVPN... "
    # shellcheck disable=SC2034
    #read -rp "Do you really want to remove OpenVPN? [y/n]: " -e -i n REMOVE
     
    #if [[ "$REMOVE" = 'y' ]]; then
        # Get OpenVPN port from the configuration
        RPORT=$(grep '^port ' /etc/openvpn/server.conf | cut -d " " -f 2)

        # Stop OpenVPN
        if [[ "$OS" =~ (fedora|arch|centos) ]]; then
            systemctl disable openvpn-server@server
            systemctl stop openvpn-server@server
            # Remove customised service
            rm /etc/systemd/system/openvpn-server@.service
        elif [[ "$OS" == "ubuntu" ]] && [[ "$VERSION_ID" == "16.04" ]]; then
            systemctl disable openvpn
            systemctl stop openvpn
        else
            systemctl disable openvpn@server
            systemctl stop openvpn@server
            # Remove customised service
            rm /etc/systemd/system/openvpn\@.service
        fi

        # Remove the iptables rules related to the script
        systemctl stop iptables-openvpn
        # Cleanup
        systemctl disable iptables-openvpn
        rm /etc/systemd/system/iptables-openvpn.service
        systemctl daemon-reload
        rm /etc/iptables/add-openvpn-rules.sh
        rm /etc/iptables/rm-openvpn-rules.sh

        # SELinux
        if hash sestatus 2>/dev/null; then
            if sestatus | grep "Current mode" | grep -qs "enforcing"; then
                if [[ "$RPORT" != '1194' ]]; then
                    semanage port -d -t openvpn_port_t -p udp "$RPORT"
                fi
            fi
        fi

        if [[ "$OS" =~ (debian|ubuntu) ]]; then
            apt-get autoremove --purge -y openvpn
            if [[ -e /etc/apt/sources.list.d/openvpn.list ]];then
                rm /etc/apt/sources.list.d/openvpn.list
                apt-get update
            fi
        elif [[ "$OS" = 'arch' ]]; then
            pacman --noconfirm -R openvpn
        elif [[ "$OS" =~ (centos|amzn) ]]; then
            yum remove -y openvpn
        elif [[ "$OS" = 'fedora' ]]; then
            dnf remove -y openvpn
        fi

        # Cleanup
        find /home/ -maxdepth 2 -name "*.ovpn" -delete
        find /root/ -maxdepth 1 -name "*.ovpn" -delete
        rm -rf /etc/openvpn
        rm -rf /usr/share/doc/openvpn*
        rm -f /etc/sysctl.d/20-openvpn.conf
        rm -rf /var/log/openvpn

        # Unbound
        if [[ -e /etc/unbound/openvpn.conf ]]; then
            removeUnbound
        fi
        echo ""
        bigecho "OpenVPN removed!"
   
}


radiusclientsetup(){

bigecho "RadiusClient Installation Started..."


apt-get -y install libgcrypt11-dev build-essential

apt-get -y install wget

if [ -d "/root/radiusplugin_v2.1a_beta1" ] || [ -d "/etc/openvpn/radius" ];then
    rm -r /root/radiusplugin_v2.1a_beta1
    rm -r /etc/openvpn/radius
fi


wget http://www.nongnu.org/radiusplugin/radiusplugin_v2.1a_beta1.tar.gz

tar xvf radiusplugin_v2.1a_beta1.tar.gz

cd radiusplugin_v2.1a_beta1

make

sleep 3

mkdir /etc/openvpn/radius

cp -r radiusplugin.so /etc/openvpn/radius

# PUBLIC_IP=$(dig @resolver1.opendns.com -t A -4 myip.opendns.com +short)
# [ -z "$PUBLIC_IP" ] && PUBLIC_IP=$(wget -t 3 -T 15 -qO- http://ipv4.icanhazip.com)


conf_bk "/etc/openvpn/radius/radius.cnf"

if [ -e "/etc/openvpn/radius/radius.cnf" ]; then

    rm /etc/openvpn/radius/radius.cnf
fi

cat >> /etc/openvpn/radius/radius.cnf <<EOF

NAS-Identifier=$PUBLIC_IP
# The service type which is sent to the RADIUS server
Service-Type=5
# The framed protocol which is sent to the RADIUS server
Framed-Protocol=1
# The NAS port type which is sent to the RADIUS server
NAS-Port-Type=5
# The NAS IP address which is sent to the RADIUS server
NAS-IP-Address=$PUBLIC_IP
# Path to the OpenVPN configfile. The plugin searches there for
# client-config-dir PATH   (searches for the path)
# status FILE                (searches for the file, version must be 1)
# client-cert-not-required (if the option is used or not)
# username-as-common-name  (if the option is used or not)
# Path to our OpenVPN configuration file. Each OpenVPN configuration file needs its own radiusplugin configuration file as well
OpenVPNConfig=/etc/openvpn/server.conf
# Support for topology option in OpenVPN 2.1
# If you don't specify anything, option "net30" (default in OpenVPN) is used.
# You can only use one of the options at the same time.
# If you use topology option "subnet", fill in the right netmask, e.g. from OpenVPN option "--server NETWORK NETMASK"
subnet=255.255.255.0
# If you use topology option "p2p", fill in the right network, e.g. from OpenVPN option "--server NETWORK NETMASK"
# p2p=10.8.0.1
# Allows the plugin to overwrite the client config in client config file directory,
# default is true
overwriteccfiles=true
# Allows the plugin to use auth control files if OpenVPN (>= 2.1 rc8) provides them.
# default is false
# useauthcontrolfile=false
# Only the accouting functionality is used, if no user name to forwarded to the plugin, the common name of certificate is used
# as user name for radius accounting.
# default is false
# accountingonly=false
# If the accounting is non essential, nonfatalaccounting can be set to true.
# If set to true all errors during the accounting procedure are ignored, which can be
# - radius accounting can fail
# - FramedRouted (if configured) maybe not configured correctly
# - errors during vendor specific attributes script execution are ignored
# But if set to true the performance is increased because OpenVPN does not block during the accounting procedure.
# default is false
nonfatalaccounting=false
# Path to a script for vendor specific attributes.
# Leave it out if you don't use an own script.
# vsascript=/root/workspace/radiusplugin_v2.0.5_beta/vsascript.pl
# Path to the pipe for communication with the vsascript.
# Leave it out if you don't use an own script.
# vsanamedpipe=/tmp/vsapipe
# A radius server definition, there could be more than one.
# The priority of the server depends on the order in this file. The first one has the highest priority.
server
{
# The UDP port for radius accounting.
acctport=1813
# The UDP port for radius authentication.
authport=1812
# The name or ip address of the radius server.
name=$YOUR_RADIUS_SERVER_IP
# How many times should the plugin send the if there is no response?
retry=1
# How long should the plugin wait for a response?
wait=1
# The shared secret.
sharedsecret=$RADIUS_SECRET
}

EOF
bigecho "Radiusclient Installation Done"
}

#################### FUNCTION DECLARATION STARTED HERE ###############################

if [[ $VPNTYPE == "ikev2" ]];then
bigecho " VPN Type $VPNTYPE"
  if [[ -z "$REMOVED" ]]; then
    vpnsetup "$@"
  else
    vpnremove "$@"
    vpnsetup "$@"
  fi
  
elif [[ "$VPNTYPE" == "openvpn" ]];then
  
bigecho " VPN Type $VPNTYPE"

 # Check if OpenVPN is already installed

 if [ -e /etc/openvpn/server.conf ] || [ ! -z "$REMOVED" ] ; then
   removeOpenVPN
   installOpenVPN
   openvpnrestart
 else
  installOpenVPN
  openvpnrestart
 fi
 # radiusclientinstallation
radiusclientsetup "$@"
openvpnrestart
  
  elif [[ "$VPNTYPE" == "openvpn-ikev2" ]];then
  # first installation for ikev2
  bigecho " VPN Type $VPNTYPE"
  if [[ -z "$REMOVED" ]]; then
    vpnsetup "$@"
  else
  
    vpnremove "$@"
    vpnsetup "$@"
  fi
  # then install openvpn
  if [ -e /etc/openvpn/server.conf ] || [ ! -z "$REMOVED" ] ; then
    removeOpenVPN
    installOpenVPN
    openvpnrestart
  else
   removeOpenVPN
   installOpenVPN
   openvpnrestart
  fi
  radiusclientsetup "$@"
  openvpnrestart
  else
  bigecho "VPN Type Not Defined"
  fi
  
  # Sending back the status of instllation
if [ -z "$APIKEY" ]
      then

      bigecho "API Key Not Found! It seems the script runs directory on the server"

      else
    
      bigecho "Sending Server Status after installation succesfully"
    if [ -z "$CLIENTHOSTNAME" ]
        then
            return_status=$(curl --data "api=$APIKEY&status=1&ip=$PUBLIC_IP&v=$VPNTYPE" $PANELURL/includes/vpnapi/serverstatus.php);
        else
            return_status=$(curl --data "api=$APIKEY&status=1&ip=$CLIENTHOSTNAME&v=$VPNTYPE" $PANELURL/includes/vpnapi/serverstatus.php);
    fi
      if [ "$return_status" == "1" ]; then
      echo "Return Status : "$return_status
      echo " Ack Done for Status Updation on Panel Side"
else
      bigecho "Seems Server not updated on Panel Side"
      bigecho "Return Message:" $return_status
      fi
      fi
    
    #  cleaning files
    rm /root/checkServerCompatibility.sh
    rm /root/install-vpn-proxy.sh
exit 0
