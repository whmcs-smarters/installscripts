
#!/bin/sh
# Created by WHMCS-Smarters www.whmcssmarters.com

exiterr()  { echo "Error: $1" >&2; exit 1; }
exiterr2() { exiterr "'apt-get install' failed."; }
conf_bk() { /bin/cp -f "$1" "$1.old-$SYS_DT" 2>/dev/null; }
bigecho() { echo; echo "## $1"; echo; }

repoName="smartersvpnpanel-decrypted"
repoPath="https://whmcs-smarters:1818e49e450cbcd0a5d4c76d338243c45807dcf9@github.com/whmcs-smarters/$repoName.git"
scriptFileName="install-smartersvpnpanel-decrypted.sh"


#Copy/Paste the below script when  needed

while getopts ":l:p:d:s:a:i:" o
do
    case "${o}" in
    l) LICENSE=${OPTARG}
    ;;
    p) DIRPATH=${OPTARG}
    ;;
    d) DOMAIN=${OPTARG}
    ;;
    s) SSHPORT=${OPTARG}
    ;;
    a) SSHPASS=${OPTARG}
    ;;
    i) SERVICEID=${OPTARG}
    ;;
    esac
done

if [ -z "$SSHPORT" ];then
    SSHPORT=22
fi

if [ -z "$SSHPASS" ];then
    SSHPASS="changethispassword"
fi

if [ -z "$DIRPATH" ];then
    DIRPATH="/var/www/html/"
else
    mkdir -p $DIRPATH
    
fi
PUBLIC_IP=$(curl ipinfo.io/ip)

if [ -z "$DOMAIN" ];then
    DOMAIN="http://$PUBLIC_IP"
fi

bigecho "SMART VPN Billing Panel Installation Started...."

apt-get update
#apt-get upgrade -y
sudo apt-get -y install mysql-server
sudo apt install apache2 -y
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get update -y
sudo apt-get install php5.6 php5.6-mbstring git php5.6-mcrypt php5.6-mysql php5.6-xml unzip zip gzip tar php5.6-curl php5.6-gd php5.6-zip  -y
sudo a2dismod php5
#sudo a2dismod php7
sudo a2enmod php5.6
sudo service apache2 restart



#cd $DIRPATH
cat /dev/null > index.html
echo "Installing ..... Please wait! It will take a few minutes" >> $DIRPATH/index.html

if [ -d "$repoName" ];then
rm -r $repoName
echo "Removing existing folder "
bigecho " Cloning ......"
git clone $repoPath
else
bigecho " Cloning ......"
git clone $repoPath
fi
FILE="$DIRPATH/configuration.php"
if [ -f "$FILE" ];then
echo "Removing existings smarterspanel files first then Moving "
rm -r $DIRPATH/*
mv -f $repoName/* $DIRPATH
else
mv -f $repoName/* $DIRPATH
fi
 
bigecho "Cloned Successfully"

cd $DIRPATH
#cd zend-loader-php5.6-linux-x86_64
cp zend-loader/ZendGuardLoader.so /usr/lib/php/20131226/

cp zend-loader/opcache.so /usr/lib/php/20131226/

# Ioncube installation
 

cp ioncube/ioncube_loader_lin_5.6.so /usr/lib/php/20131226

if ! grep -qs "Smarters VPN Panel Installation" /etc/php/5.6/apache2/php.ini; then

cat >> /etc/php/5.6/apache2/php.ini <<EOF
; Smarters VPN Panel Installation
zend_extension = /usr/lib/php/20131226/ioncube_loader_lin_5.6.so
zend_extension = /usr/lib/php/20131226/ZendGuardLoader.so

EOF

cat >> /etc/php/5.6/cli/php.ini <<EOF
; Smarters VPN Panel Installation
zend_extension = /usr/lib/php/20131226/ioncube_loader_lin_5.6.so
zend_extension = /usr/lib/php/20131226/ZendGuardLoader.so
EOF

fi

bigecho " Setting up Cron"

cat >> /etc/crontab <<EOF
*/5 * * * * /usr/bin/php -q $DIRPATH/crons/cron.php

EOF

bigecho " Mysql Database Createding and Importing...."

mysql -u root -e "create database vpn_smarters_billing";


mysql -u root  vpn_smarters_billing < $DIRPATH/sqldump/vpn_billing.sql

# Creating mysql useername and password

MYSQLPASS=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 10)
MYSQLUSER=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 8)
VPNPORT=0

mysql -u root -e "CREATE USER '$MYSQLUSER'@'localhost' IDENTIFIED BY '$MYSQLPASS'"
mysql -u root -e "GRANT ALL PRIVILEGES ON * . * TO '$MYSQLUSER'@'localhost'"
mysql -u root vpn_smarters_billing -e "UPDATE tblconfiguration SET value = '$DOMAIN' WHERE setting='SystemURL'";
mysql -u root vpn_smarters_billing -e "UPDATE tblconfiguration SET value = '$DOMAIN' WHERE setting='Domain'";
mysql -u root vpn_smarters_billing -e "UPDATE tbladdonmodules SET value = '$LICENSE' WHERE module = 'vpnpanel' AND setting = 'license'";
mysql -u root vpn_smarters_billing -e "UPDATE tbladdonmodules SET value = '' WHERE module = 'vpnpanel' AND setting = 'localkey'";
mysql -u root vpn_smarters_billing -e "INSERT INTO server_list(server_name, flag, server_ip, server_category, sshport, server_port, pskkey, mainserver, sshpass, status,createdUploaded) VALUES ('Main Server','$DOMAIN/modules/addons/vpnpanel/assets/flags/png/no_flag.png','$PUBLIC_IP','openvpn','$SSHPORT','$VPNPORT','$SERVICEID',1,'$SSHPASS',1,'Created')";

bigecho "Database Created / User Creatd / Configuration Updated"


rm configuration.php

cat >> configuration.php <<EOF
<?php
\$license = 'WHMCS-29kavnamq1';
\$db_host = 'localhost';
\$db_port = '';
\$db_username = '$MYSQLUSER';
\$db_password = '$MYSQLPASS';
\$db_name = 'vpn_smarters_billing';
\$cc_encryption_hash = 'ZzruzaTJMDHVK9o4TDHagNUmYi2aBb1qBiL0iuzVY7Hz6WtQp0QwEAJsJBsaDkr4';
\$templates_compiledir = 'templates_c';
\$mysql_charset = 'utf8';
\$autoauthkey= 'loveysingh';
EOF

chmod 444 configuration.php
chmod 777 templates_c
chmod 777 admin/templates_c

if [ -d modules/servers/vpnservernoapi/lib/qr_code/temp ];then
chmod 777 modules/servers/vpnservernoapi/lib/qr_code/temp
else
mkdir -p modules/servers/vpnservernoapi/lib/qr_code/temp
chmod 777 modules/servers/vpnservernoapi/lib/qr_code/temp
fi



sudo service apache2 restart

bigecho " Installation Done"

bigecho "Your Mysql Username : $MYSQLUSER"
bigecho "Your Mysql Password : $MYSQLPASS"
bigecho "VPN Panel Admin URL http://$PUBLIC_IP/admin"
bigecho " Admin Username : admin"
bigecho "Admin Password : admin"
#optional
#apt-get install -y sendmail php-mail;

if [ -f /root/$scriptFileName ];then
rm /root/$scriptFileName
bigecho " Script install-smartersvpnpanel-decrypted.sh removed !!"
fi
if [ -f /root/checkServerCompatibility.sh ];then
rm /root/checkServerCompatibility.sh
bigecho " Removed checkServerCompatibility.sh Script !!"
fi
if [ -f "$DIRPATH/index.html" ];then

rm $DIRPATH/index.html
echo " Removed Index.html dummy file "
fi
# Update Configuration via mysql

# Radius Server Installation ....

#!/bin/sh
# Created by WHMCS-Smarters www.whmcssmarters.com

# Assiging valus MYSQLHOST
MYSQLHOST='localhost'
MYSQLDB='vpn_smarters_billing'

# while getopts ":h:p:l:s:d:" o
# do
#     case "${o}" in
#     h) MYSQLHOST=${OPTARG}
#     ;;
#     p) MYSQLPORT=${OPTARG}
#     ;;
#     l) MYSQLLOGIN=${OPTARG}
#     ;;
#     s) MYSQLPASS=${OPTARG}
#     ;;
#     d) MYSQLDB=${OPTARG}
#     esac
# done

if [ -z "$MYSQLPORT" ]; then
    MYSQLPORT=3306
fi


bigecho "Freeradius Installation Started ......"

# check if alredy installed, so need to be removed first

 
if [ -e "/etc/freeradius/3.0/mods-enabled/sql" ];then

bigecho "We found freeradius folder seems it's already installed. So it need to be removed first"

sudo systemctl stop freeradius.service # stopping freeradius first

# sudo apt-get -y remove freeradius
# sudo apt-get -y remove --auto-remove freeradius
# sudo apt-get -y purge freeradius
# sudo apt-get purge -y --auto-remove freeradius
rm /etc/freeradius/3.0/mods-enabled/sql


bigecho "Removed Freeradius Successfully"

fi

sudo apt -y install freeradius freeradius-mysql freeradius-utils

bigecho "Passing variables are : mysqlhost - $MYSQLHOST , mysqldatabase : $MYSQLDB, mysqlport $MYSQLPORT , mysqusername : $MYSQLUSER , mysqlpassword : $MYSQLPASS"
cat >> /etc/freeradius/3.0/mods-enabled/sql <<EOF
sql {
driver = "rlm_sql_mysql"

dialect = "mysql"

# Connection info:
server = "$MYSQLHOST"
port = $MYSQLPORT
login = "$MYSQLUSER"
password = "$MYSQLPASS"

# Database table configuration for everything except Oracle
radius_db = "$MYSQLDB"

 acct_table1 = "radacct"
 acct_table2 = "radacct"

    # Allow for storing data after authentication
    postauth_table = "radpostauth"

    # Tables containing 'check' items
    authcheck_table = "radcheck"
    groupcheck_table = "radgroupcheck"

    # Tables containing 'reply' items
    authreply_table = "radreply"
    groupreply_table = "radgroupreply"

    # Table to keep group info
    usergroup_table = "radusergroup"



    # Remove stale session if checkrad does not see a double login
    delete_stale_sessions = yes

# Set to ‘yes’ to read radius clients from the database (‘nas’ table)
# Clients will ONLY be read on server startup.
read_clients = yes

# Table to keep radius client info
client_table = "nas"

# This entry should be used for the default instance (sql {})
# of the SQL module.
group_attribute = "SQL-Group"

\$INCLUDE \${modconfdir}/\${.:name}/main/\${dialect}/queries.conf
}
EOF

#/etc/freeradius/3.0/mods-enabled/sql


sudo chgrp -h freerad /etc/freeradius/3.0/mods-available/sql
sudo chown -R freerad:freerad /etc/freeradius/3.0/mods-enabled/sql
sudo systemctl restart freeradius.service
echo " Radius Server is ready"

bigecho " Sending Status back"
return_status=$(curl --data "s=1&p=$DOMAIN&serviceid=$SERVICEID" https://www.whmcssmarters.com/clients/panel_installation_status.php);
echo "Return Message: $return_status"
