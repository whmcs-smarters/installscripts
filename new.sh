#!/bin/bash

#To debug the programme please uncomment below command and execute again. 

#set -x 

#export LANG=en_US.UTF-8

#sleep `echo $RANDOM|grep -Eo '.$'`

 
###########################################################
###         WHMCSSMARTERS vpnpanel setup 2020           ###
###                  Version 1.0                        ###
###                                                     ###
### Copyright (c) 2020                                  ###
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

#################################################################################
###  README Instrutions before executing this script.                         ### 
###  ------------------------------------------------                         ### 
#################################################################################

##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################
func_usage()
        {
         printf "
Usage: 
   
  Information options:
  ---------------------------------------
  -f		    Control file
                    install: LICENSE~DIECTORY~DOMAIN~SSHPORT~SSHPASS~PSKKEY 
                    upgrade: LICENSE~DIECTORY~DOMAIN~SSHPORT~SSHPASS~PSKKEY~MYSQLUSER~MYSQLPASS~MYSQLDB

  -i	            To install vpnpanel
  -u                To upgrade vpnpanel


  Syntax:

  $0 -f <control file txt> -i
  $0 -f <control file txt> -u

  Other standard options are:  
  ---------------------------------------
  -h,--help         Display this help. 
  -v,--version      Display version information. 


  README Instructions before execute
  ---------------------------------------
  upgrade.txt	    control file created to upgrade vpnpanel while installing.
"
        }
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_var()
        {
         SCRIPT_VERSION="WHMCSSMARTERS vpnpanel setup version 1.0[[2020/06/01]]"         
         DATE=`date +"%Y%m%d"`
         TIME=`date +"%H%M%S"`
	 SYS_DATE=`date +%F-%T`
	 export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
	 APT_CMD=`which apt-get`
	 ADD_REPO_CMD=`which add-apt-repository`
	 A2DIS_MOD_CMD=`which a2dismod`
	 A2EN_MOD_CMD=`which a2enmod`
	 SER_CMD=`which service`
	 #REPO_NAME="smartersvpnpanel"
	 REPO_NAME="smarterspanel-org"
         GIT_TOKEN="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"
         REPO_PATH=https://whmcs-smarters:$GIT_TOKEN@github.com/whmcs-smarters/
	#REPO_PATH="https://amansmarters:194f07247ea811f481b76c7c79f32a88dd3ba399@github.com/whmcs-smarters"
	 PHP_LIB_FOLDER="/usr/lib/php/20170718"
	 PHP_APACHE2_INI="/etc/php/7.2/apache2/php.ini"
	 PHP_CLI_INI="/etc/php/7.2/cli/php.ini"
         VAR_COUNT=`cat $CONTROL_FILE|grep -v "^#"|grep -v "^/"|tr "~" "\n"|wc -l`
         VAR_LICENSE=`cat $CONTROL_FILE|grep -v "^#"|grep -v "^/"|cut -d"~" -f1`
         VAR_DIRPATH=`cat $CONTROL_FILE|grep -v "^#"|grep -v "^/"|cut -d"~" -f2`
         VAR_DOMAIN=`cat $CONTROL_FILE|grep -v "^#"|grep -v "^/"|cut -d"~" -f3`
         VAR_SSHPORT=`cat $CONTROL_FILE|grep -v "^#"|grep -v "^/"|cut -d"~" -f4`
         VAR_SSHPASS=`cat $CONTROL_FILE|grep -v "^#"|grep -v "^/"|cut -d"~" -f5`
         VAR_SERVICEID=`cat $CONTROL_FILE|grep -v "^#"|grep -v "^/"|cut -d"~" -f6`
	 VAR_WHMLICENSE=`cat $CONTROL_FILE|grep -v "^#"|grep -v "^/"|cut -d"~" -f7`
	 VAR_PREV=`cat  $CONTROL_FILE|grep -v "^#"|grep -v "^/"`
	 MYSQLUSER=`cat $CONTROL_FILE|grep -v "^#"|grep -v "^/"|cut -d"~" -f8`
	 if [[ -z "$MYSQLUSER" ]]
         then
               MYSQLUSER=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 8)
         fi
	 MYSQLPASS=`cat $CONTROL_FILE|grep -v "^#"|grep -v "^/"|cut -d"~" -f9`
         if [[ -z "$MYSQLPASS" ]]
         then
               MYSQLPASS=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 10)
         fi
	 MYSQLDB=`cat $CONTROL_FILE|grep -v "^#"|grep -v "^/"|cut -d"~" -f10`
         if [[ -z "$MYSQLDB" ]]
         then
               MYSQLDB="vpn_smarters_billing_$MYSQLUSER"
         fi
	 VAR_PWD=`pwd`
	 SERVICE_CMD=`which service`
	 MYSQL_CMD=`which mysql`
	 CRON_PATH=`which crontab`
	 SERVER_PUB_IP=`curl ipinfo.io/ip`
	 VPN_PORT=0
	 MYSQLHOST='localhost'
	 MYSQLPORT=3306
	 LOG_FILE=`basename $0 ".sh"`
	 VAR_ENCRYPTION_HASH=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1`
	}
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_packages()
        {
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Installing packages." 1>$LOG_FILE.log 2>&1
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: System updates." 1>>$LOG_FILE.log 2>&1
         $APT_CMD update -y 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
         func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: System updates completed successfully." 1>>$LOG_FILE.log 2>&1
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Install MySQL server." 1>>$LOG_FILE.log 2>&1
	 $APT_CMD -yq install mysql-server 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
         func_status "$STATUS"
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: MySQL server installation completed successfully." 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Install apache2 server." 1>>$LOG_FILE.log 2>&1
         $APT_CMD install apache2 -y 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
         func_status "$STATUS"
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Apache2 server installation completed successfully." 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Install software properties." 1>>$LOG_FILE.log 2>&1
         $APT_CMD install software-properties-common -y 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
         func_status "$STATUS"
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Software properties installation completed successfully." 1>>$LOG_FILE.log 2>&1
         #echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Add apt repository." 1>>$LOG_FILE.log 2>&1
         # $ADD_REPO_CMD ppa:ondrej/php -y 1>>$LOG_FILE.log 2>&1
         # STATUS=`echo $?`
         # func_status "$STATUS"
         # echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: REpository added successfully." 1>>$LOG_FILE.log 2>&1
         # echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: System updates." 1>>$LOG_FILE.log 2>&1
         $APT_CMD update -y 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
         func_status "$STATUS"
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: System updates completed successfully." 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Install php stack." 1>>$LOG_FILE.log 2>&1
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: php7.2 php7.2-mbstring git php7.2-mcrypt php7.2-mysql php7.2-xml unzip zip gzip tar php7.2-curl php7.2-gd php7.2-zip" 1>>$LOG_FILE.log 2>&1
         (sleep 5; echo Y;)|$APT_CMD install  php7.2 php7.2-mbstring git php7.2-mysql php7.2-xml unzip zip gzip tar php7.2-curl php7.2-gd php7.2-zip 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
         func_status "$STATUS"
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: PHP stack installation completed successfully." 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Disable specific modules php5." 1>>$LOG_FILE.log 2>&1
	 func_var
         $A2DIS_MOD_CMD php5 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
	 CHECK=`cat $LOG_FILE.log|grep "ERROR: Module php5 does not exist!"|wc -l`
	 func_check "$CHECK"
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Module disabled successfully." 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Disable specific modules php7." 1>>$LOG_FILE.log 2>&1
         $A2DIS_MOD_CMD php7 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
         CHECK=`cat $LOG_FILE.log|grep "ERROR: Module php7 does not exist!"|wc -l`
	 func_check "$CHECK"
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Module disabled successfully." 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Enable module php7.2." 1>>$LOG_FILE.log 2>&1
         $A2EN_MOD_CMD "php7.2" 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
         func_status "$STATUS"
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Module enabled successfully." 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Restart apache2 server." 1>>$LOG_FILE.log 2>&1
         $SER_CMD apache2 restart 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
         func_status "$STATUS"
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Restarted apache2 server successfully." 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Restart MySQL server." 1>>$LOG_FILE.log 2>&1
         $SER_CMD mysql restart 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
         func_status "$STATUS"
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Restarted MySQL server successfully." 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Install send mail server." 1>>$LOG_FILE.log 2>&1
         $APT_CMD install sendmail -y 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
         func_status "$STATUS"
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Installation completed successfully." 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Install php mail server." 1>>$LOG_FILE.log 2>&1
         $APT_CMD install php-mail -y 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
         func_status "$STATUS"
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: Installation completed successfully." 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: All packages installed successfully." 1>>$LOG_FILE.log 2>&1
        }
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_gitclone()
        {
         printf " \n"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: starting clone repo $REPO_NAME" 1>>$LOG_FILE.log 2>&1
         if [[ -d $VAR_PWD/$REPO_NAME ]]
         then
	     echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: $REPO_NAME repo exist." 1>>$LOG_FILE.log 2>&1
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removing $REPO_NAME repo " 1>>$LOG_FILE.log 2>&1
	     rm -rf $VAR_PWD/$REPO_NAME 1>>$LOG_FILE.log 2>&1
	     STATUS=`echo $?`
             func_status "$STATUS"
	     echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removed $REPO_NAME repo " 1>>$LOG_FILE.log 2>&1
	     echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: previous $REPO_NAME has been removed." 1>>$LOG_FILE.log 2>&1
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: checking git status " 1>>$LOG_FILE.log 2>&1
	     which  git 1>>$LOG_FILE.log 2>&1
             STATUS=`echo $?`
             func_status "$STATUS"
	     echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: git running on server " 1>>$LOG_FILE.log 2>&1
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: cloning repo $REPO_NAME " 1>>$LOG_FILE.log 2>&1
             git clone $REPO_PATH/$REPO_NAME.git 1>>$LOG_FILE.log 2>&1
	     STATUS=`echo $?`
             func_status "$STATUS"
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: cloning of  repo $REPO_NAME has been completed " 1>>$LOG_FILE.log 2>&1
     	else
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: checking git status " 1>>$LOG_FILE.log 2>&1
             which  git 1>>$LOG_FILE.log 2>&1
             STATUS=`echo $?`
             func_status "$STATUS"
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: git running on server " 1>>$LOG_FILE.log 2>&1
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: cloning repo $REPO_NAME " 1>>$LOG_FILE.log 2>&1
             git clone $REPO_PATH/$REPO_NAME.git 1>>$LOG_FILE.log 2>&1
             STATUS=`echo $?`
             func_status "$STATUS"
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: cloning of  repo $REPO_NAME has been completed " 1>>$LOG_FILE.log 2>&1
	fi
        if [[ -f $VAR_DIRPATH/configuration.php ]]
        then
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: smarterspanel data files exists " 1>>$LOG_FILE.log 2>&1
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removing smarterspanel data files " 1>>$LOG_FILE.log 2>&1
	     rm -rf $VAR_DIRPATH/* 1>>$LOG_FILE.log 2>&1
	     STATUS=`echo $?`
             func_status "$STATUS"
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: old smarterspanel data files has been removed " 1>>$LOG_FILE.log 2>&1
	     echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: creating directory $VAR_DIRPATH" 1>>$LOG_FILE.log 2>&1
	     mkdir -p $VAR_DIRPATH 1>>$LOG_FILE.log 2>&1
	     STATUS=`echo $?`
	     func_status "$STATUS"
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: directory $VAR_DIRPATH has been successfully created" 1>>$LOG_FILE.log 2>&1

	     echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: copying smarterspanel new data files to $VAR_DIRPATH" 1>>$LOG_FILE.log 2>&1
	     mv -f $REPO_NAME/* $VAR_DIRPATH 1>>$LOG_FILE.log 2>&1
	     STATUS=`echo $?`
             func_status "$STATUS"
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: smarterspanel new data files has been copied to $VAR_DIRPATH" 1>>$LOG_FILE.log 2>&1
	     echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: remove empty cloned repo $REPO_NAME" 1>>$LOG_FILE.log 2>&1
             rm  -rf $REPO_NAME 1>>$LOG_FILE.log 2>&1
             STATUS=`echo $?`
             func_status "$STATUS"
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: empty repo has been removed" 1>>$LOG_FILE.log 2>&1
	else
	     echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: creating directory $VAR_DIRPATH" 1>>$LOG_FILE.log 2>&1
             mkdir -p $VAR_DIRPATH 1>>$LOG_FILE.log 2>&1
             STATUS=`echo $?`
             func_status "$STATUS"
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: directory $VAR_DIRPATH has been successfully created" 1>>$LOG_FILE.log 2>&1
echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: copying smarterspanel new data files to $VAR_DIRPATH" 1>>$LOG_FILE.log 2>&1
             mv -f $REPO_NAME/* $VAR_DIRPATH 1>>$LOG_FILE.log 2>&1
             STATUS=`echo $?`
             func_status "$STATUS"
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: smarterspanel new data files has been copied to $VAR_DIRPATH" 1>>$LOG_FILE.log 2>&1
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: remove empty cloned repo $REPO_NAME" 1>>$LOG_FILE.log 2>&1
             rm  -rf $REPO_NAME 1>>$LOG_FILE.log 2>&1
             STATUS=`echo $?`
             func_status "$STATUS"
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: empty repo has been removed" 1>>$LOG_FILE.log 2>&1

	fi
        echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: repo $REPO_NAME has been cloned succesfully" 1>>$LOG_FILE.log 2>&1

        }
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_install_zendioncube()
        {
	 #echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: zend and ioncube installation started" 1>>$LOG_FILE.log 2>&1
        # echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: copying zendguard loader to $PHP_LIB_FOLDER" 1>>$LOG_FILE.log 2>&1
	 #cp $VAR_DIRPATH/zend-loader/ZendGuardLoader.so $PHP_LIB_FOLDER 1>>$LOG_FILE.log 2>&1
        # STATUS=`echo $?`
        # func_status "$STATUS"
         #echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: zendguard loader has been copied to $PHP_LIB_FOLDER" 1>>$LOG_FILE.log 2>&1
	# echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: copying opcache to $PHP_LIB_FOLDER" 1>>$LOG_FILE.log 2>&1
	# cp $VAR_DIRPATH/zend-loader/opcache.so $PHP_LIB_FOLDER 1>>$LOG_FILE.log 2>&1
	 #STATUS=`echo $?`
	 #func_status "$STATUS"
	 #echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: opcache has been copied to $PHP_LIB_FOLDER" 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: copying ioncube loader to $PHP_LIB_FOLDER" 1>>$LOG_FILE.log 2>&1
	 cp $VAR_DIRPATH/ioncube/ioncube_loader_lin_7.2.so $PHP_LIB_FOLDER 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: ioncube loader has been copied to $PHP_LIB_FOLDER" 1>>$LOG_FILE.log 2>&1

	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: adding zend extension directory to $PHP_APACHE2_INI" 1>>$LOG_FILE.log 2>&1
	 COUNT=`cat $PHP_APACHE2_INI | grep "Smarters VPN Panel Installation"|wc -l`
	 if [[ $COUNT == 0 ]]
         then
             echo "; Smarters VPN Panel Installation" >> $PHP_APACHE2_INI
             echo "zend_extension = $PHP_LIB_FOLDER/ioncube_loader_lin_7.2.so" >> $PHP_APACHE2_INI
	     echo "zend_extension = $PHP_LIB_FOLDER/ZendGuardLoader.so" >> $PHP_APACHE2_INI
	     echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: added zend extension directory to $PHP_APACHE2_INI" 1>>$LOG_FILE.log 2>&1
	 fi
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: adding zend extension directory to $PHP_CLI_INI" 1>>$LOG_FILE.log 2>&1
         COUNT=`cat $PHP_CLI_INI | grep "Smarters VPN Panel Installation"|wc -l`
	 if [[ $COUNT == 0 ]]
         then
	     echo "; Smarters VPN Panel Installation" >> $PHP_CLI_INI
	     echo "zend_extension = $PHP_LIB_FOLDER/ioncube_loader_lin_7.2.so" >> $PHP_CLI_INI
	     #echo "zend_extension = $PHP_LIB_FOLDER/ZendGuardLoader.so" >> $PHP_CLI_INI
	     echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: added zend extension directory to $PHP_CLI_INI" 1>>$LOG_FILE.log 2>&1
	 fi
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: zend and ioncube installation has been completed successfully" 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: restarting apache2 server" 1>>$LOG_FILE.log 2>&1
	 $SERVICE_CMD apache2 restart 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: apache2 server has been successfully restarted." 1>>$LOG_FILE.log 2>&1

        }
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_cronjob()
        {
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: setting cron for panel automation" 1>>$LOG_FILE.log 2>&1
	 echo "#*/5 * * * * /usr/bin/php -q $VAR_DIRPATH/crons/cron.php" >> /etc/crontab
         STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: cronjob has been added for panel automation" 1>>$LOG_FILE.log 2>&1
        }
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_mysqldb_create()
        {
         if [[ -f ~/.my.cnf ]]
         then
                echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removing ~/.my.cnf configuration file " 1>>$LOG_FILE.log 2>&1
                rm -f ~/.my.cnf 1>>$LOG_FILE.log 2>&1
                STATUS=`echo $?`
                func_status "$STATUS"
                echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: ~/.my.cnf configuration file has been removed" 1>>$LOG_FILE.log 2>&1
         fi
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: creating mysql database" 1>>$LOG_FILE.log 2>&1
         $MYSQL_CMD -u root -e "create database $MYSQLDB" 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: mysql database $MYSQLDB has been created" 1>>$LOG_FILE.log 2>&1
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: import data into database $MYSQLDB" 1>>$LOG_FILE.log 2>&1
	 $MYSQL_CMD -u root $MYSQLDB < $VAR_DIRPATH/sqldump/vpn_billing.sql 1>>$LOG_FILE.log 2>&1
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: data has been successfully imported into database $MYSQLDB" 1>>$LOG_FILE.log 2>&1
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: creating mysql username and password for application" 1>>$LOG_FILE.log 2>&1
	 $MYSQL_CMD -u root -e "CREATE USER '$MYSQLUSER'@'localhost' IDENTIFIED BY '$MYSQLPASS'" 1>>$LOG_FILE.log 2>&1 
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: mysql user has been created" 1>>$LOG_FILE.log 2>&1
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: grant privileges to mysql user" 1>>$LOG_FILE.log 2>&1
         $MYSQL_CMD -u root -e "GRANT ALL PRIVILEGES ON * . * TO '$MYSQLUSER'@'localhost'" 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: privileges have been granted to mysql user" 1>>$LOG_FILE.log 2>&1
	 if [[ $VAR_COUNT -ne 9 ]]
         then
               echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: create control file for upgrade" 1>>$LOG_FILE.log 2>&1
	       echo "#LICENSE~DIECTORY~DOMAIN~SSHPORT~SSHPASS~PSKKEY~WHMLICENSE~MYSQLUSER~MYSQLPASS~MYSQLDB" > upgrade.txt
	       echo "$VAR_PREV~$MYSQLUSER~$MYSQLPASS~$MYSQLDB" >> upgrade.txt 
	       STATUS=`echo $?`
	       func_status "$STATUS" 
	       echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: control file upgrade.txt has been created for upgrade" 1>>$LOG_FILE.log 2>&1
	 fi
        }
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_config()
        {
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: updating configuration file $VAR_DIRPATH/configuration.php" 1>>$LOG_FILE.log 2>&1
	 if [[ -f $VAR_DIRPATH/configuration.php ]]
         then
	     echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: configuration file $VAR_DIRPATH/configuration.php available" 1>>$LOG_FILE.log 2>&1
	     echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removing configuration file $VAR_DIRPATH/configuration.php " 1>>$LOG_FILE.log 2>&1
	     rm -f $VAR_DIRPATH/configuration.php 1>>$LOG_FILE.log 2>&1
             STATUS=`echo $?`
	     func_status "$STATUS"
	     echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removed configuration file $VAR_DIRPATH/configuration.php " 1>>$LOG_FILE.log 2>&1
	     echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: updating configuration file $VAR_DIRPATH/configuration.php " 1>>$LOG_FILE.log 2>&1
	     echo "<?php" > $VAR_DIRPATH/configuration.php
	     echo "\$license = '$VAR_WHMLICENSE';" >> $VAR_DIRPATH/configuration.php
	     echo "\$db_host = 'localhost';" >> $VAR_DIRPATH/configuration.php
	     echo "\$db_username = '$MYSQLUSER';" >> $VAR_DIRPATH/configuration.php
	     echo "\$db_password = '$MYSQLPASS';" >> $VAR_DIRPATH/configuration.php
	     echo "\$db_name = '$MYSQLDB';" >> $VAR_DIRPATH/configuration.php
	     echo "\$cc_encryption_hash = '$VAR_ENCRYPTION_HASH';" >> $VAR_DIRPATH/configuration.php
	     echo "\$templates_compiledir = 'templates_c';" >> $VAR_DIRPATH/configuration.php
	     echo "\$mysql_charset = 'utf8';" >> $VAR_DIRPATH/configuration.php
	     echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: configuration file $VAR_DIRPATH/configuration.php updated " 1>>$LOG_FILE.log 2>&1
	 else
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: updating configuration file $VAR_DIRPATH/configuration.php " 1>>$LOG_FILE.log 2>&1
             echo "<?php" > $VAR_DIRPATH/configuration.php
             echo "\$license = '$VAR_WHMLICENSE';" >> $VAR_DIRPATH/configuration.php
             echo "\$db_host = 'localhost';" >> $VAR_DIRPATH/configuration.php
             echo "\$db_username = '$MYSQLUSER';" >> $VAR_DIRPATH/configuration.php
             echo "\$db_password = '$MYSQLPASS';" >> $VAR_DIRPATH/configuration.php
             echo "\$db_name = '$MYSQLDB';" >> $VAR_DIRPATH/configuration.php
             echo "\$cc_encryption_hash = '$VAR_ENCRYPTION_HASH';" >> $VAR_DIRPATH/configuration.php
             echo "\$templates_compiledir = 'templates_c';" >> $VAR_DIRPATH/configuration.php
             echo "\$mysql_charset = 'utf8';" >> $VAR_DIRPATH/configuration.php
             echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: configuration file $VAR_DIRPATH/configuration.php updated " 1>>$LOG_FILE.log 2>&1   
         fi
	}
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_mysqlupdate()
        {
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: update domain in table tblconfiguration" 1>>$LOG_FILE.log 2>&1
         echo "UPDATE tblconfiguration SET value = '$VAR_DOMAIN' WHERE setting = 'SystemURL';" > update.sql
	 $MYSQL_CMD -u $MYSQLUSER $MYSQLDB < update.sql 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
         func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: domain has been updated in table tblconfiguration" 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: update domain in table tblconfiguration" 1>>$LOG_FILE.log 2>&1
	 echo "UPDATE tblconfiguration SET value = '$VAR_DOMAIN' WHERE setting = 'Domain';" > update.sql
	 $MYSQL_CMD -u $MYSQLUSER $MYSQLDB < update.sql 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: domain has been updated in table tblconfiguration" 1>>$LOG_FILE.log 2>&1
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: update license in table tbladdonmodules" 1>>$LOG_FILE.log 2>&1
         echo "UPDATE tbladdonmodules SET value = '$VAR_LICENSE'  WHERE module = 'vpnpanel' AND setting = 'license';" > update.sql
	 $MYSQL_CMD -u $MYSQLUSER $MYSQLDB < update.sql 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: license has been updated in table tbladdonmodules" 1>>$LOG_FILE.log 2>&1
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: update localkey in table tbladdonmodules" 1>>$LOG_FILE.log 2>&1
	 echo "UPDATE tbladdonmodules SET value = ''  WHERE module = 'vpnpanel' AND setting = 'localkey';" > update.sql
	 $MYSQL_CMD -u $MYSQLUSER $MYSQLDB < update.sql 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: localkey has been updated in table tbladdonmodules" 1>>$LOG_FILE.log 2>&1
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: update table server_list" 1>>$LOG_FILE.log 2>&1
	 echo "UPDATE server_list SET mainserver = 0 WHERE 1;" > update.sql
	 $MYSQL_CMD -u $MYSQLUSER $MYSQLDB < update.sql 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: table server_list has been updated" 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: delete public ip from table server_list" 1>>$LOG_FILE.log 2>&1
         echo "DELETE FROM server_list WHERE server_ip = '$SERVER_PUB_IP';" > update.sql
	 $MYSQL_CMD -u $MYSQLUSER $MYSQLDB < update.sql 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: public ip has been deleted from table server_list" 1>>$LOG_FILE.log 2>&1
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: add/update server details to table server_list" 1>>$LOG_FILE.log 2>&1
	 echo "INSERT INTO server_list(server_name, flag, server_ip, server_category, sshport, server_port, pskkey, mainserver, sshpass, status,createdUploaded, server_group) VALUES ('Main Server','$VAR_DOMAIN/modules/addons/vpnpanel/assets/flags/png/no_flag.png','$SERVER_PUB_IP','openvpn','$VAR_SSHPORT','$VPN_PORT','$VAR_SERVICEID',1,'$VAR_SSHPASS',1,'Created','All');" > update.sql
	 $MYSQL_CMD -u $MYSQLUSER $MYSQLDB < update.sql 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: server details has been added/updated to table server_list" 1>>$LOG_FILE.log 2>&1
	 if [[ -f update.sql ]]
         then
	       echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removing file created by function" 1>>$LOG_FILE.log 2>&1
	       rm -f update.sql 1>>$LOG_FILE.log 2>&1
	       STATUS=`echo $?`
	       func_status "$STATUS"
	       echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: files createdfrom function has been removed" 1>>$LOG_FILE.log 2>&1

	 fi
        }
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_permission()
        {
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: updating file configuration.php permission " 1>>$LOG_FILE.log 2>&1
	 chmod 444 $VAR_DIRPATH/configuration.php 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: changed file configuration.php permission " 1>>$LOG_FILE.log 2>&1
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: updating directory templates_c permission " 1>>$LOG_FILE.log 2>&1
	 chmod 777 $VAR_DIRPATH/templates_c 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: updated directory templates_c permission " 1>>$LOG_FILE.log 2>&1
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: updating directory admin/templates_c permission " 1>>$LOG_FILE.log 2>&1
	 chmod 777 $VAR_DIRPATH/admin/templates_c 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: updated directory admin/templates_c permission " 1>>$LOG_FILE.log 2>&1
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: updating directory downloads permission " 1>>$LOG_FILE.log 2>&1
	 chmod 777 $VAR_DIRPATH/downloads 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: updating directory attachments permission " 1>>$LOG_FILE.log 2>&1
	 chmod 777 $VAR_DIRPATH/attachments 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: updated directory attachments permission " 1>>$LOG_FILE.log 2>&1
 	}
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_cleanup()
        {
         if [[ -f $VAR_PWD/$1 ]] 
         then
		 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removing script $VAR_PWD/$1 " 1>>$LOG_FILE.log 2>&1
		 rm -f $VAR_PWD/$1 1>>$LOG_FILE.log 2>&1
                 STATUS=`echo $?`
		 func_status "$STATUS"
		 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: script $1 has been removed " 1>>$LOG_FILE.log 2>&1
         fi
         if [[ -f $VAR_PWD/checkMainServerCompatibility.sh ]]
	 then
		 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removing script $VAR_PWD/checkMainServerCompatibility.sh " 1>>$LOG_FILE.log 2>&1
		 rm -f $VAR_PWD/checkMainServerCompatibility.sh 1>>$LOG_FILE.log 2>&1
		 STATUS=`echo $?`
		 func_status "$STATUS"
		 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: script $VAR_PWD/checkMainServerCompatibility.sh has been removed" 1>>$LOG_FILE.log 2>&1
	 fi
           if [[ -f $VAR_PWD/new.sh ]]
     then
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removing script $VAR_PWD/new.sh " 1>>$LOG_FILE.log 2>&1
         rm -f $VAR_PWD/new.sh 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
         func_status "$STATUS"
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: script $VAR_PWD/new.sh has been removed" 1>>$LOG_FILE.log 2>&1
     fi
         if [[ -f $VAR_DIRPATH/index.html ]]
         then
		 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removing $VAR_DIRPATH/index.html " 1>>$LOG_FILE.log 2>&1
		 rm -f $VAR_DIRPATH/index.html
		 STATUS=`echo $?`
		 func_status "$STATUS"
		 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removed $VAR_DIRPATH/index.html " 1>>$LOG_FILE.log 2>&1
	 fi
	 if [[ -d $VAR_DIRPATH ]]
	 then
               cp $LOG_FILE.log $VAR_DIRPATH/ 
	       STATUS=`echo $?`
	       func_status "$STATUS"
	 fi
 	}
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_mycnf()
        {
	 if [[ -f ~/.my.cnf ]]
	 then
	        echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removing ~/.my.cnf configuration file " 1>>$LOG_FILE.log 2>&1
		rm -f ~/.my.cnf 1>>$LOG_FILE.log 2>&1
		STATUS=`echo $?`
		func_status "$STATUS"
                echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: ~/.my.cnf configuration file has been removed" 1>>$LOG_FILE.log 2>&1
	 fi

	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: creating ~/.my.cnf configuration file " 1>>$LOG_FILE.log 2>&1
	 echo "[mysql]" > ~/.my.cnf 
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "user = $MYSQLUSER" >> ~/.my.cnf
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "password = '$MYSQLPASS'" >> ~/.my.cnf
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 printf " \n"
	 printf " \n"
         echo "[mysqldump]" >> ~/.my.cnf
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "user = $MYSQLUSER" >> ~/.my.cnf
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "password = '$MYSQLPASS'" >> ~/.my.cnf
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: ~/.my.cnf configuration file has been created " 1>>$LOG_FILE.log 2>&1
        }
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_freeradius()
        {
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: starting process to install freeradius " 1>>$LOG_FILE.log 2>&1
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: checking if freeradius installed " 1>>$LOG_FILE.log 2>&1
	 $SERVICE_CMD freeradius restart 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 if [[ $STATUS != 0 ]]
	 then
               echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: uninstall freeradius " 1>>$LOG_FILE.log 2>&1
	       echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: stopping freeradius " 1>>$LOG_FILE.log 2>&1
	       $SERVICE_CMD freeradius stop 1>>$LOG_FILE.log 2>&1
	       STATUS=`echo $?`
	       echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: freeradius has been stopped " 1>>$LOG_FILE.log 2>&1
	       if [[ -d /etc/freeradius/3.0 ]]
	       then
		      echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removing freeradius installation directory " 1>>$LOG_FILE.log 2>&1
		      rm -rf /etc/freeradius 1>>$LOG_FILE.log 2>&1
		      STATUS=`echo $?`
		      func_status "$STATUS"
		      echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: freeradius installation directory has been removed " 1>>$LOG_FILE.log 2>&1
	       fi
               echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: purging freeradius packages " 1>>$LOG_FILE.log 2>&1
               (sleep 5; echo Y;)|$APT_CMD purge freeradius-common freeradius freeradius-mysql freeradius-utils 1>>$LOG_FILE.log 2>&1
               STATUS=`echo $?`
               func_status "$STATUS"
               echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: freeradius packages has been purged " 1>>$LOG_FILE.log 2>&1
	       echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: freeradius uninstalled " 1>>$LOG_FILE.log 2>&1
	       echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: installing freeradius " 1>>$LOG_FILE.log 2>&1
	       echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: installing freeradius packages " 1>>$LOG_FILE.log 2>&1
	       (sleep 5; echo Y;)|$APT_CMD install freeradius-common freeradius freeradius-mysql freeradius-utils 1>>$LOG_FILE.log 2>&1
	       STATUS=`echo $?`
	       func_status "$STATUS"
	       echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: freeradius packages have been installed successfully" 1>>$LOG_FILE.log 2>&1
	       echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: restarting freeradius " 1>>$LOG_FILE.log 2>&1
	       $SERVICE_CMD freeradius restart 1>>$LOG_FILE.log 2>&1
	       STATUS=`echo $?`
	       func_status "$STATUS"
	       echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: freeradius has been restarted " 1>>$LOG_FILE.log 2>&1
	       echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: freeradius has been installed successfully " 1>>$LOG_FILE.log 2>&1
         else
               echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: installing freeradius " 1>>$LOG_FILE.log 2>&1
	       echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: purging freeradius packages" 1>>$LOG_FILE.log 2>&1
               (sleep 5; echo Y;)|$APT_CMD purge freeradius-common freeradius freeradius-mysql freeradius-utils 1>>$LOG_FILE.log 2>&1
	       STATUS=`echo $?`
	       func_status "$STATUS"
	       echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: freeradius packages have been purged successfully" 1>>$LOG_FILE.log 2>&1
               echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: installing freeradius packages " 1>>$LOG_FILE.log 2>&1
               (sleep 5; echo Y;)|$APT_CMD install freeradius-common freeradius freeradius-mysql freeradius-utils 1>>$LOG_FILE.log 2>&1
               STATUS=`echo $?`
               func_status "$STATUS"
               echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: freeradius packages have been installed successfully" 1>>$LOG_FILE.log 2>&1
               echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: restarting freeradius " 1>>$LOG_FILE.log 2>&1
               $SERVICE_CMD freeradius restart 1>>$LOG_FILE.log 2>&1
               STATUS=`echo $?`
               func_status "$STATUS"
               echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: freeradius has been restarted " 1>>$LOG_FILE.log 2>&1
               echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: freeradius has been installed successfully " 1>>$LOG_FILE.log 2>&1
	       
	 fi
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: stoping freeradius " 1>>$LOG_FILE.log 2>&1
	 $SERVICE_CMD freeradius stop 1>>$LOG_FILE.log 2>&1
	 STATUS=`echo $?`
	 func_status "$STATUS"
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: freeradius has been stopped " 1>>$LOG_FILE.log 2>&1
	 echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: creating freeradius sql configuration file " 1>>$LOG_FILE.log 2>&1
cat > /etc/freeradius/3.0/mods-enabled/sql <<EOF
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

        echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: freeradius sql configuration file has been created " 1>>$LOG_FILE.log 2>&1
        echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: changing group of sql configuration file " 1>>$LOG_FILE.log 2>&1
	chgrp -h freerad /etc/freeradius/3.0/mods-available/sql 1>>$LOG_FILE.log 2>&1
	STATUS=`echo $?`
	func_status "$STATUS"
	echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: sql configuration file group has been changed " 1>>$LOG_FILE.log 2>&1
	echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: changing owner of sql configuration file " 1>>$LOG_FILE.log 2>&1
	chown -R freerad:freerad /etc/freeradius/3.0/mods-enabled/sql 1>>$LOG_FILE.log 2>&1
	STATUS=`echo $?`
	func_status "$STATUS"
	echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: sql configuration file onwers have been changed " 1>>$LOG_FILE.log 2>&1

	echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: starting process to enable freeradius default site " 1>>$LOG_FILE.log 2>&1
	if [[ -f /etc/freeradius/3.0/sites-enabled/default ]]
	then
		echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: creating archive directory for default configurations " 1>>$LOG_FILE.log 2>&1
		mkdir -p /etc/freeradius/3.0/sites-enabled/archive 1>>$LOG_FILE.log 2>&1
		STATUS=`echo $?`
		func_status "$STATUS"
		echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: archive directory has been created " 1>>$LOG_FILE.log 2>&1
		echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: taking backup of old default configuration " 1>>$LOG_FILE.log 2>&1
		cp /etc/freeradius/3.0/sites-enabled/default /etc/freeradius/3.0/sites-enabled/archive/default-$DATE$TIME 1>>$LOG_FILE.log 2>&1
                STATUS=`echo $?`
		func_status "$STATUS"
		echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: backup has been completed " 1>>$LOG_FILE.log 2>&1
		echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removing old default configuration " 1>>$LOG_FILE.log 2>&1
		rm -f /etc/freeradius/3.0/sites-enabled/default 1>>$LOG_FILE.log 2>&1
		STATUS=`echo $?`
		func_status "$STATUS"
		echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: removed old default configuration " 1>>$LOG_FILE.log 2>&1
		if [[ -f $VAR_DIRPATH/radiusconf/default ]]
		then
			echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: copy the new default configuration " 1>>$LOG_FILE.log 2>&1
			cp $VAR_DIRPATH/radiusconf/default /etc/freeradius/3.0/sites-enabled/ 1>>$LOG_FILE.log 2>&1
			STATUS=`echo $?`
			func_status "$STATUS"
			echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: new default configuration has been copied to respective location " 1>>$LOG_FILE.log 2>&1
			echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: change group of configuration file " 1>>$LOG_FILE.log 2>&1
			chgrp -h freerad /etc/freeradius/3.0/sites-enabled/default 1>>$LOG_FILE.log 2>&1
			STATUS=`echo $?`
			func_status "$STATUS"
			echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: configuration file group has been changed" 1>>$LOG_FILE.log 2>&1
			echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: change owner of configuration file " 1>>$LOG_FILE.log 2>&1
			chown -R freerad:freerad /etc/freeradius/3.0/sites-enabled/default 1>>$LOG_FILE.log 2>&1
			STATUS=`echo $?`
			func_status "$STATUS"
			echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: configuration file owner have been changed" 1>>$LOG_FILE.log 2>&1
		fi
        fi
        echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: freeradius has been installed successfully" 1>>$LOG_FILE.log 2>&1
	echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: restarting freeradius service " 1>>$LOG_FILE.log 2>&1
        $SERVICE_CMD freeradius restart 1>>$LOG_FILE.log 2>&1
	STATUS=`echo $?`
	func_status "$STATUS"
	echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: freeradius service has been restarted successfully " 1>>$LOG_FILE.log 2>&1
        }
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_defaultrun()
        {
	 func_var	
         if [[ $SCRIPT_VERSION ]]
         then
             printf "$SCRIPT_VERSION \n"
             printf "Copyright (c) 2020, WHMCSSMARTERS and/or its affiliates. All Rights Reserved.\n"
             func_usage
         fi
        }
###############################################################################################################################################Function information:
#
#
##############################################################################################################################################

func_varcheck()
        {
         if [[ ! $1 ]]
         then
               echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: ERROR: Deafult option needs an arguement $2"
	       func_usage
	       exit
         fi
        }
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_status()
        {
         if [[ $1 != 0 ]]
         then
               echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: ERROR: failed."
               exit
         fi
        }
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_returnstatus()
        {
         echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: vpnpanel return status information" 1>>$LOG_FILE.log 2>&1
	 echo VAR_DOMAIN : $VAR_DOMAIN
	 echo VAR_SERVICEID : $VAR_SERVICEID
	 curl --data "s=1&p=$VAR_DOMAIN&serviceid=$VAR_SERVICEID&t=installed" https://www.whmcssmarters.com/clients/panel_installation_status.php 1>>$LOG_FILE.log 2>&1
         STATUS=`echo $?`
         #func_status "$STATUS"
        }


##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################

func_check()
        {
         if [[ $1 == 1 ]]
         then
               echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: WARNING: Check log. "
	 else
	       func_status "$STATUS"
         fi

        }
	
##############################################################################################################################################
#Function information:
#
#
##############################################################################################################################################                                              #Getopts    Defination#
##############################################################################################################################################
if ! options=$(getopt -o  hf:viu -l help,--control-file:,version,install,upgrade -- "$@")
then
    # something went wrong, getopt will put out an error message for us
    exit 1
fi

set -- $options

while [ $# -gt 0 ]
do
    case $1 in
    -h|--help)
       printf " \n"
       SCRIPT_VERSION="WHMCSSMARTERS vpnpanel setup version 1.0[[2020/06/01]]"
       if [[ $SCRIPT_VERSION ]]
       then
             printf "$SCRIPT_VERSION \n"
             printf "Copyright (c) 2020, WHMCSSMARTERS and/or its affiliates. All Rights Reserved.\n"
             func_usage
       fi
       exit
       ;;
    -i|--install)
      func_varcheck "$CONTROL_FILE" "-f"
      func_var
      func_packages
      func_gitclone
      func_install_zendioncube
      func_cronjob
      func_mysqldb_create
      func_mycnf
      func_config
      func_mysqlupdate
      func_permission
      func_freeradius
      func_returnstatus
      func_cleanup
      exit
      shift
      ;;
    -u|--upgrade)
      func_varcheck "$CONTROL_FILE" "-f"
      func_var
      echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: starting vpnpanel upgrade process " 1>$LOG_FILE.log 2>&1
      func_gitclone
      func_config
      func_mysqlupdate
      func_permission
      func_freeradius
      func_returnstatus
      func_cleanup
      echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: INFO: vpnpanel has been upgraded successfully " 1>>$LOG_FILE.log 2>&1
      exit
      shift
      ;;
    -f|--control-file)
      CONTROL_FILE=`echo $2|tr -d "[']"`
      if [[ ! -f $CONTROL_FILE ]]
      then
            echo "`date +"%Y%m%d"` `date +"%H:%M:%S"` vpnpanel setup: ERROR: Default arguement needs an valid file -f. "
            exit
      fi
      shift
      ;;
    -v|--version)
      printf " \n"
      SCRIPT_VERSION="WHMCSSMARTERS vpnpanel setup version 1.0[[2020/06/01]]"
      if [[ $SCRIPT_VERSION ]]
      then
            printf "$SCRIPT_VERSION\n"
            printf "Copyright (c) 2020,  WHMCSSMARTERS and/or its affiliates. All Rights Reserved.\n"
            printf " \n"
            printf "Run $0 -h/--help for help information.\n"
            exit
      fi
      shift
      ;;

    (--) 
      shift;
      break;;

    (-*) 
      echo "$0: error - unrecognized option $1" 1>&2;
      exit 1;;

    (*)
      break;;
   esac
  shift
done
##############################################################################################################################################
#func_defaultrun
##############################################################################################################################################
