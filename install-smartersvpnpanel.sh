
#!/bin/sh
# Created by WHMCS-Smarters www.whmcssmarters.com
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
SYS_DT=$(date +%F-%T)

exiterr()  { echo "Error: $1" >&2; exit 1; }
exiterr2() { exiterr "'apt-get install' failed."; }
conf_bk() { /bin/cp -f "$1" "$1.old-$SYS_DT" 2>/dev/null; }
bigecho() { echo; echo "## $1"; echo; }

repoName="smartersvpnpanel"
repoPath="https://amansmarters:aa29246e0d9acd108307e63fd8bf5e6b0cfe957b@github.com/whmcs-smarters/$repoName.git"
scriptFileName="install-smartersvpnpanel.sh"


#Copy/Paste the below script when  needed

while getopts ":l:p:d:s:a:i:g:u:q:b:" o
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
    g) UPGRADE=${OPTARG}
    ;;
    u) MYSQLUSER=${OPTARG}
    ;;
    q) MYSQLPASS=${OPTARG}
    ;;
    b) MYSQLDB=${OPTARG}
    ;;
    esac
done


function installPackages()
{
bigecho "Packages Installation Started ...."
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
bigecho " Package Installation Done."
 
}


function cloneGitFiles(){

if [ -d "$repoName" ];then
rm -r $repoName
echo "Removing existing folder "
bigecho " Cloning ......"
git clone $repoPath
else
bigecho " Cloning ......"
git clone $repoPath
fi
mv -f $repoName/* $DIRPATH

#FILE="$DIRPATH/configuration.php"

#if [ -f "$FILE" ];then
#echo "Removing existings smarterspanel files first then Moving "
#rm -r $DIRPATH/*
#mv -f $repoName/* $DIRPATH
#else
#mv -f $repoName/* $DIRPATH
#fi
 
bigecho "Cloned Successfully"
}

function zendioncubeInstallation () {
bigecho " Zend / ioncube Installation Startard..."
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
bigecho "Zend & IonCube Installation Done!"
sudo service apache2 restart
}

function settinCron(){

bigecho " Setting up Cron..."

cat >> /etc/crontab <<EOF
*/5 * * * * /usr/bin/php -q $DIRPATH/crons/cron.php
#* * * * * /usr/bin/php -q $DIRPATH/modules/addons/vpnpanel/cron/cleanStaleSessions.php
EOF
bigecho "Cron Set for VPN Panel Success !"
}

function DatbaseCreate(){

bigecho " Mysql Database Createding and Importing...."

mysql -u root -e "create database $MYSQLDB";


mysql -u root  $MYSQLDB < $DIRPATH/sqldump/vpn_billing.sql

# Creating mysql useername and password


mysql -u root -e "CREATE USER '$MYSQLUSER'@'localhost' IDENTIFIED BY '$MYSQLPASS'"
mysql -u root -e "GRANT ALL PRIVILEGES ON * . * TO '$MYSQLUSER'@'localhost'"
DatabaseUpdate
bigecho "Database Created / User Creatd / Configuration Updated"

}
 function DatabaseUpdate(){
 createCNF
 mysql -u $MYSQLUSER $MYSQLDB -e "UPDATE tblconfiguration SET value = '$DOMAIN' WHERE setting='SystemURL'";
 mysql -u $MYSQLUSER $MYSQLDB -e "UPDATE tblconfiguration SET value = '$DOMAIN' WHERE setting='Domain'";
 mysql -u $MYSQLUSER $MYSQLDB -e "UPDATE tbladdonmodules SET value = '$LICENSE' WHERE module = 'vpnpanel' AND setting = 'license'";
 mysql -u $MYSQLUSER $MYSQLDB -e "UPDATE tbladdonmodules SET value = '' WHERE module = 'vpnpanel' AND setting = 'localkey'";
 mysql -u $MYSQLUSER $MYSQLDB -e "UPDATE server_list SET mainserver = 0 WHERE server_ip = $PUBLIC_IP";
 mysql -u $MYSQLUSER $MYSQLDB -e "INSERT INTO server_list(server_name, flag, server_ip, server_category, sshport, server_port, pskkey, mainserver, sshpass, status,createdUploaded) VALUES ('Main Server','$DOMAIN/modules/addons/vpnpanel/assets/flags/png/no_flag.png','$PUBLIC_IP','openvpn','$SSHPORT','$VPNPORT','$SERVICEID',1,'$SSHPASS',1,'Created')";

}
function CreateConfigFile(){
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
}
function SettingPermission ()
{
cd $DIRPATH
bigecho "Setting up the Permission"
chmod 444 "$DIRPATH/configuration.php"
chmod 777 "$DIRPATH/templates_c"
chmod 777 "$DIRPATH/admin/templates_c"
chmod 777 "$DIRPATH/downloads"
chmod 777 "$DIRPATH/attachments"

if [ -d modules/servers/vpnservernoapi/lib/qr_code/temp ];then
chmod 777 modules/servers/vpnservernoapi/lib/qr_code/temp
else
mkdir -p modules/servers/vpnservernoapi/lib/qr_code/temp
chmod 777 modules/servers/vpnservernoapi/lib/qr_code/temp
fi

bigecho "Premission granted !"
}



 
function scriptRemove()
{

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
if [ -f "~/.my.cnf" ];then
rm ~/.my.cnf
echo "Removed CNF File"
fi
}
# Update Configuration via mysql

# Radius Server Installation ....

if [ -z "$MYSQLPORT" ]; then
    MYSQLPORT=3306
fi

function installFreeradius()
{

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


if [ -f "$DIRPATH/radiusconf/default" ];then
conf_bk "/etc/freeradius/3.0/sites-enabled/default"
rm /etc/freeradius/3.0/sites-enabled/default
cp $DIRPATH/radiusconf/default /etc/freeradius/3.0/sites-enabled/
sudo chgrp -h freerad /etc/freeradius/3.0/sites-enabled/default
sudo chown -R freerad:freerad /etc/freeradius/3.0/sites-enabled/default
fi
 
sudo chgrp -h freerad /etc/freeradius/3.0/mods-available/sql
sudo chown -R freerad:freerad /etc/freeradius/3.0/mods-enabled/sql
sudo systemctl restart freeradius.service
echo " Radius Server is ready"
} # installFreeRadius brace
function TempMessageDisplayed ()
{
cat /dev/null > $DIRPATH/index.html

echo "Installing ..... Please wait! It will take a few minutes" >> $DIRPATH/index.html
}

function createCNF(){
cat >> ~/.my.cnf <<EOF
[mysql]
user = $MYSQLUSER
password = $MYSQLPASS

[mysqldump]
user = $MYSQLUSER
password = $MYSQLPASS
EOF
}
##### Function Declaration #######


VPNPORT=0
MYSQLHOST='localhost'
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



if [ -z "$UPGRADE" ];then

MYSQLDB='vpn_smarters_billing'
MYSQLPASS=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 10)
MYSQLUSER=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 8)

bigecho "SMART VPN Billing Panel Installation Started...."
 
installPackages
TempMessageDisplayed
cloneGitFiles
zendioncubeInstallation
settinCron
DatbaseCreate
CreateConfigFile
SettingPermission
installFreeradius
else
bigecho "SMART VPN Billing Panel Upgradation Started...."
TempMessageDisplayed
cloneGitFiles
DatabaseUpdate
SettingPermission
installFreeradius
 fi
scriptRemove

bigecho "Done"
 
bigecho "Your Mysql Username : $MYSQLUSER"
bigecho "Your Mysql Password : $MYSQLPASS"
bigecho "VPN Panel Admin URL http://$PUBLIC_IP/admin"
bigecho " Admin Username : admin"
bigecho "Admin Password : admin"
#optional
#apt-get install -y sendmail php-mail;
bigecho " Sending Status back"
return_status=$(curl --data "s=1&p=$DOMAIN&serviceid=$SERVICEID" https://www.whmcssmarters.com/clients/panel_installation_status.php);
echo "Return Message: $return_status"
