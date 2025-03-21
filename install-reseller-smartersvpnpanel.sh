#!/bin/bash

# Created by WHMCS-Smarters www.whmcssmarters.com
#FileVersion 2.4
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
SYS_DT=$(date +%F-%T)

exiterr()  { echo "Error: $1" >&2; exit 1; }
exiterr2() { exiterr "'apt-get install' failed."; }
conf_bk() { /bin/cp -f "$1" "$1.old-$SYS_DT" 2>/dev/null; }
bigecho() { echo; echo "## $1"; echo; }

repoName="smartersresellervpnpanel"
repoPath="https://amansmarters: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@github.com/whmcs-smarters/$repoName.git"
scriptFileName="install-reseller-smartersvpnpanel.sh"


#Copy/Paste the below script when  needed

while getopts ":l:p:d:s:a:i:g:u:q:b:m:w:" o
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
    m) MAINPANELURL=${OPTARG}
    ;;
    w) WHMCSLICENSE=${OPTARG}
    ;;
    esac
done


function installPackages(){
bigecho "Packages Installation Started ...."
apt-get update -y
#apt-get upgrade -y
sudo apt-get -yq install mysql-server
sudo apt install apache2 -y
sudo apt-get install software-properties-common -y
#sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get update -y
sudo apt-get install php7.2 php7.2-mbstring git php7.2-mcrypt php7.2-mysql php7.2-xml unzip zip gzip tar php7.2-curl php7.2-gd php7.2-zip  -y
sudo a2dismod php5
sudo a2dismod php7
sudo a2enmod php7.2
sudo service apache2 restart
service mysql restart
sudo apt-get install sendmail -y
sudo apt-get install php-mail -y
bigecho " Package Installation Done."
 
}

function cloneGitFiles(){

if [ -d "/root/$repoName" ];then
rm -r "/root/"$repoName
echo "Removing existing folder "
bigecho " Cloning ......"
git clone $repoPath
else
bigecho " Cloning ......"
git clone $repoPath
fi
#mv -f $repoName/* $DIRPATH

FILE="$DIRPATH/configuration.php"

if [ -f "$FILE" ];then
echo "Removing existings smarterspanel files first then Moving "
rm -r $DIRPATH/*
mv -f $repoName/* $DIRPATH
else
mv -f $repoName/* $DIRPATH
fi
 
bigecho "Cloned Successfully"
}

function zendioncubeInstallation () {
bigecho " Zend / ioncube Installation Startard..."
#cd $DIRPATH
#cd zend-loader-php7.2-linux-x86_64
cp "$DIRPATH/zend-loader/ZendGuardLoader.so" /usr/lib/php/20170718/

cp "$DIRPATH/zend-loader/opcache.so" /usr/lib/php/20170718/

# Ioncube installation
 

cp "$DIRPATH/ioncube/ioncube_loader_lin_7.2.so" /usr/lib/php/20170718

if ! grep -qs "Smarters VPN Panel Installation" /etc/php/7.2/apache2/php.ini; then

cat >> /etc/php/7.2/apache2/php.ini <<EOF
; Smarters VPN Panel Installation
zend_extension = /usr/lib/php/20170718/ioncube_loader_lin_7.2.so
zend_extension = /usr/lib/php/20170718/ZendGuardLoader.so

EOF

cat >> /etc/php/7.2/cli/php.ini <<EOF
; Smarters VPN Panel Installation
zend_extension = /usr/lib/php/20170718/ioncube_loader_lin_7.2.so
zend_extension = /usr/lib/php/20170718/ZendGuardLoader.so
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
 
 bigecho " Started Updating Database using User : $MYSQLUSER and DB name $MYSQLDB";
 mysql -u $MYSQLUSER $MYSQLDB -e "UPDATE tblconfiguration SET value = '$DOMAIN' WHERE setting='SystemURL'";
 mysql -u $MYSQLUSER $MYSQLDB -e "UPDATE tblconfiguration SET value = '$DOMAIN' WHERE setting='Domain'";
 mysql -u $MYSQLUSER $MYSQLDB -e "UPDATE tbladdonmodules SET value = '$LICENSE' WHERE module = 'ResellerAutoBilling' AND setting = 'license'";
 mysql -u $MYSQLUSER $MYSQLDB -e "UPDATE tbladdonmodules SET value = '' WHERE module = 'ResellerAutoBilling' AND setting = 'localkey'";
 #mysql -u $MYSQLUSER $MYSQLDB -e "UPDATE server_list SET mainserver = 0 WHERE 1";
 #mysql -u $MYSQLUSER $MYSQLDB -e "DELETE FROM server_list WHERE server_ip = '$PUBLIC_IP'";
 #mysql -u $MYSQLUSER $MYSQLDB -e "INSERT INTO server_list(server_name, flag, server_ip, server_category, sshport, server_port, pskkey, mainserver, sshpass, status,createdUploaded) VALUES ('Main Server','$DOMAIN/modules/addons/vpnpanel/assets/flags/png/no_flag.png','$PUBLIC_IP','openvpn','$SSHPORT','$VPNPORT','$SERVICEID',1,'$SSHPASS',1,'Created')";

}
function CreateConfigFile(){
rm "$DIRPATH/configuration.php"

cat >> "$DIRPATH/configuration.php" <<EOF
<?php
\$license = '$WHMCSLICENSE';
\$db_host = 'localhost';
\$db_port = '';
\$db_username = '$MYSQLUSER';
\$db_password = '$MYSQLPASS';
\$db_name = '$MYSQLDB';
\$cc_encryption_hash = 'ZzruzaTJMDHVK9o4TDHagNUmYi2aBb1qBiL0iuzVY7Hz6WtQp0QwEAJsJBsaDkr4';
\$templates_compiledir = 'templates_c';
\$mysql_charset = 'utf8';
\$autoauthkey= 'loveysingh';
EOF
}
function SettingPermission ()
{
#cd $DIRPATH
bigecho "Setting up the Permission"
chmod 444 "$DIRPATH/configuration.php"
chmod 777 "$DIRPATH/templates_c"
chmod 777 "$DIRPATH/admin/templates_c"
chmod 777 "$DIRPATH/downloads"
chmod 777 "$DIRPATH/attachments"

if [ -d "$DIRPATH/modules/servers/vpnservernoapi/lib/qr_code/temp" ];then
chmod 777 "$DIRPATH/modules/servers/vpnservernoapi/lib/qr_code/temp"
else
mkdir -p "$DIRPATH/modules/servers/vpnservernoapi/lib/qr_code/temp"
chmod 777 "$DIRPATH/modules/servers/vpnservernoapi/lib/qr_code/temp"
fi

bigecho "Premission granted !"
}

function scriptRemove()
{

if [ -f /root/$scriptFileName ];then
rm /root/$scriptFileName
bigecho " Script install-smart...sh removed !!"
fi
if [ -f /root/checkMainServerCompatibility.sh ];then
rm /root/checkMainServerCompatibility.sh
bigecho " Removed checkMainServerCompatibility.sh.sh Script !!"
fi
if [ -f "$DIRPATH/index.html" ];then

rm $DIRPATH/index.html
echo " Removed Index.html dummy file "
fi
 
rm "/root/.my.cnf" || echo "CNF File not removed"
 
}
# Update Configuration via mysql

# Radius Server Installation ....

if [ -z "$MYSQLPORT" ]; then
    MYSQLPORT=3306
fi


function TempMessageDisplayed ()
{
cat /dev/null > $DIRPATH/index.html

echo "Installing ..... Please wait! It will take a few minutes" >> $DIRPATH/index.html
}

function createCNF(){
cat >> ~/.my.cnf <<EOF
[mysql]
user = $MYSQLUSER
password = '$MYSQLPASS'

[mysqldump]
user = $MYSQLUSER
password = '$MYSQLPASS'
EOF
}
##### Function Declaration #######


VPNPORT=0
MYSQLHOST='localhost'
PUBLIC_IP=$(curl ipinfo.io/ip)

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


if [ -z "$DOMAIN" ];then
    DOMAIN="http://$PUBLIC_IP"
fi



if [ -z "$UPGRADE" ];then


MYSQLPASS=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 10)
MYSQLUSER=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 8)
MYSQLDB="vpn_smarters_billing_$MYSQLUSER"

bigecho "SMART VPN Billing Panel Installation Started...."
 
installPackages
TempMessageDisplayed
cloneGitFiles
zendioncubeInstallation
settinCron
DatbaseCreate
CreateConfigFile
SettingPermission
 
bigecho " Sending Status back"
return_status=$(curl --data "s=1&p=$DOMAIN&serviceid=$SERVICEID&t=installed" $MAINPANELURL/reseller-panel_installation_status.php);
echo "Return Message: $return_status"
else
bigecho "SMART VPN Billing Panel Upgradation Started...."
TempMessageDisplayed
cloneGitFiles
DatabaseUpdate
CreateConfigFile
SettingPermission
installFreeradius
bigecho " Sending Status back"
return_status=$(curl --data "s=1&p=$DOMAIN&serviceid=$SERVICEID&t=upgraded" $MAINPANELURL/reseller-panel_installation_status.php);
echo "Return Message: $return_status"
 fi
scriptRemove

bigecho "Done"
 
bigecho "Your Mysql Username : $MYSQLUSER"
bigecho "Your Mysql Password : $MYSQLPASS"
bigecho "VPN Panel Admin URL http://$PUBLIC_IP/admin"
bigecho " Admin Username : admin"
bigecho "Admin Password : admin"
#optional
#apt-get install -y sendmail php-mail -y
