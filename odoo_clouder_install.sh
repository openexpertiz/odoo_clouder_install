#!/bin/bash
################################################################################
# Script for installing Odoo and Clouder on Ubuntu 14.04 and 16.04 (could be used for other version too)
# /!\ BETA version, do NOT use in production!
# Authors: Amaury, Insaf, Yenthe Van Ginneken
#-------------------------------------------------------------------------------
# This script will install Odoo and Clouder on your Ubuntu server. It can install multiple Odoo instances
# in one Ubuntu because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano odoo_clouder_install.sh
# Place this content in it and then make the file executable:
# sudo chmod +x odoo_clouder_install.sh
# Execute the script to install:
# ./odoo_clouder_install
################################################################################
 
##fixed parameters
#odoo
OE_USER="odoo"
OE_HOME="/$OE_USER"
OE_HOME_EXT="/$OE_USER/${OE_USER}-server"
#The default port where this Odoo instance will run under (provided you use the command -c in the terminal)
#Set to true if you want to install it, false if you don't need it or have it already installed.
INSTALL_WKHTMLTOPDF="True"
#Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
OE_PORT="8069"
#Choose the Odoo version which you want to install. For example: 9.0, 8.0, 7.0 or saas-6. When using 'trunk' the master version will be installed.
#IMPORTANT! This script contains extra libraries that are specifically needed for Odoo 9.0
OE_VERSION="8.0"
# Set this to True if you want to install Odoo 9 Enterprise!
IS_ENTERPRISE="False"
#set the superadmin password
OE_SUPERADMIN="admin-OE2017"
OE_CONFIG="${OE_USER}-server"

##
###  WKHTMLTOPDF download links
## === Ubuntu Trusty x64 & x32 === (for other distributions please replace these two links,
## in order to have correct version of wkhtmltox installed, for a danger note refer to 
## https://www.odoo.com/documentation/8.0/setup/install.html#deb ):
WKHTMLTOX_X64=http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb
WKHTMLTOX_X32=http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-i386.deb

#--------------------------------------------------
# Set Locale en_US.UTF-8 for PostgreSQL
#--------------------------------------------------
echo "*********************************"
echo "*                               *"
echo "*       Changing Locales        *"
echo "*                               *"
echo "*********************************"
# Configure timezone and locale
echo -e "\n---- Setting Locales  ----"
sudo locale-gen --purge "en_US.UTF-8" && \
echo -e 'LANG="en_US.UTF-8"\nLANGUAGE="en_US:en"\n' > /etc/default/locale && \
sudo dpkg-reconfigure --frontend=noninteractive locales && \
sudo update-locale LANG=en_US.UTF-8
#---------------------------------------------------
# Timezone for Paris, change as needed
#---------------------------------------------------
echo -e "\n---- Setting Time Zone  ----"
echo "Europe/Paris" > /etc/timezone && \
sudo dpkg-reconfigure -f noninteractive tzdata && \
#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server ----"
sudo apt-get install postgresql libpq-dev -y

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n---- Install dependencies for Odoo install and management ----"
sudo apt-get -y install wget curl git python-pip gdebi-core unzip supervisor
sudo apt-get -y install build-essential libldap2-dev libsasl2-dev libxml2-dev libxslt-dev libevent-dev libjpeg-dev libjpeg8-dev libtiff5-dev

echo -e "\n---- Install build dependencies for Python 2.7.9 ----"
sudo apt-get -y install libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev zlib1g-dev
sudo ln -s /lib/x86_64-linux-gnu/libz.so.1 /lib/libz.so

echo -e "\n---- Install and Upgrade pip and virtualenv ----"
sudo pip install --upgrade pip
sudo pip install --upgrade virtualenv

echo -e "\n---- Install python packages ----"
sudo apt-get install python-dateutil python-feedparser python-ldap python-libxslt1 python-lxml python-mako python-openid python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-reportlab python-simplejson python-tz python-vatnumber python-vobject python-werkzeug python-xlwt python-yaml python-docutils python-psutil python-mock python-unittest2 python-jinja2 python-pypdf python-decorator python-requests python-passlib python-geoip python-unicodecsv python-serial python-pillow -y

echo -e "\n---- Install additional python dependencies ----"
sudo pip install --upgrade gdata psycogreen
# This is for compatibility with Ubuntu 16.04. Will work on 14.04
sudo -H pip install --upgrade suds

echo -e "\n---- Install Odoo python dependencies in requirements.txt ----"
sudo pip install -r --upgrade $OE_HOME_EXT/requirements.txt

echo -e "\n--- Install other required packages"
sudo apt-get install --upgrade node-clean-css -y
sudo apt-get install --upgrade node-less -y
sudo apt-get install --upgrade python-gevent -y

echo "************************************"
echo "*                                  *"
echo "*         Clouder Libraries        *"
echo "*                                  *"
echo "************************************"
echo -e "\n---- Install required libraries for Clouder ----"
sudo pip install --upgrade simplejson lxml pytz psycopg2 werkzeug pyyaml mako platypus unittest2 reportlab decorator pillow requests 
sudo pip install --upgrade jinja2 pyPdf passlib psutil
sudo apt-get install python-dateutil python-pychart python-decorator python-docutils python-passlib python-openid python-babel

echo -e "\n---- Install and Upgrade paramiko and erppeek ----"
# This is required for OCA/Connector and Clouder
sudo pip install --upgrade paramiko
sudo pip install --upgrade erppeek

#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO 9 ----"
  #pick up correct one from x64 & x32 versions:
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url=$WKHTMLTOX_X64
  else
      _url=$WKHTMLTOX_X32
  fi
  sudo wget $_url
  sudo gdebi --n `basename $_url`
  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  echo "Wkhtmltopdf isn't installed due to the choice of the user!"
fi
	
echo -e "\n---- Create ODOO system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER
#The user should also be added to the sudo'ers group.
sudo adduser $OE_USER sudo

echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/

if [ $IS_ENTERPRISE = "True" ]; then
    # Odoo Enterprise install!
	echo -e "\n--- Create symlink for node"
    sudo ln -s /usr/bin/nodejs /usr/bin/node
	sudo su $OE_USER -c "mkdir $OE_HOME/enterprise"
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise/addons"
	
    echo -e "\n---- Adding Enterprise code under $OE_HOME/enterprise/addons ----"
    sudo git clone --depth 1 --branch 9.0 https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons"

    echo -e "\n---- Installing Enterprise specific libraries ----"
    sudo apt-get install nodejs npm
    sudo npm install -g less
    sudo npm install -g less-plugin-clean-css
else 
    echo -e "\n---- Create custom module directory ----"
    sudo su $OE_USER -c "mkdir $OE_HOME/custom"
    sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons" 
fi	

echo -e "\n---- Create community module directory ----"
sudo su $OE_USER -c "mkdir $OE_HOME/odoo-addons-{available,enabled}"
cd $OE_HOME/odoo-addons-available
sudo su $OE_USER -c "git clone --depth 1 --branch 8.0 --single-branch https://github.com/OCA/server-tools.git"

echo -e "\n---- Create connector module directory ----"
sudo su $OE_USER -c "git clone --depth 1 --branch 8.0 --single-branch https://github.com/OCA/connector.git"

echo -e "\n---- Create nicolas-petit/web_create/clouder directory ----"
sudo su $OE_USER -c "mkdir $OE_HOME/odoo-addons-available/nicolas-petit"
sudo su $OE_USER -c "mkdir $OE_HOME/odoo-addons-available/nicolas-petit/web_create"
cd $OE_HOME/odoo-addons-available/nicolas-petit/web_create
sudo su $OE_USER -c "git clone --depth 1 --branch web_create --single-branch https://github.com/nicolas-petit/clouder.git"

echo -e "\n---- Create clouder-community/8.1/clouder directory ----"
sudo su $OE_USER -c "mkdir $OE_HOME/odoo-addons-available/clouder-community"
sudo su $OE_USER -c "mkdir $OE_HOME/odoo-addons-available/clouder-community/8.1"
cd $OE_HOME/odoo-addons-available/clouder-community/8.1
sudo su $OE_USER -c "git clone --depth 1 --branch 8.1 --single-branch https://github.com/clouder-community/clouder.git"

echo -e "\n---- Link the enabled addons among the available module directory ----"
cd $OE_HOME/odoo-addons-enabled
sudo su $OE_USER -c "ln -s ../odoo-addons-available/server-tools/disable_openerp_online/"
sudo su $OE_USER -c "ln -s ../odoo-addons-available/server-tools/cron_run_manually/"
sudo su $OE_USER -c "ln -s ../odoo-addons-available/connector/connect* ."
## If we want to use nicolas-petit/web_create/clouder version, then uncomment it:
sudo su $OE_USER -c "ln -s ../odoo-addons-available/nicolas-petit/web_create/clouder/cloud* ."
## Else if we want to use clouder-community/8.1/clouder version, then uncomment it:
#sudo su $OE_USER -c "ln -s cloude* ../odoo-addons-available/clouder-community/8.1/clouder/cloud* ."

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "* Create server config file"
sudo cp $OE_HOME_EXT/debian/openerp-server.conf /etc/${OE_CONFIG}.conf
sudo chown $OE_USER:$OE_USER /etc/${OE_CONFIG}.conf
sudo chmod 640 /etc/${OE_CONFIG}.conf

echo -e "* Change server config file"
sudo sed -i s/"db_user = .*"/"db_user = $OE_USER"/g /etc/${OE_CONFIG}.conf
sudo sed -i s/"; admin_passwd.*"/"admin_passwd = $OE_SUPERADMIN"/g /etc/${OE_CONFIG}.conf
sudo su root -c "echo 'logfile = /var/log/$OE_USER/$OE_CONFIG$1.log' >> /etc/${OE_CONFIG}.conf"
if [  $IS_ENTERPRISE = "True" ]; then
    sudo su root -c "echo 'addons_path=$OE_HOME/enterprise/addons,$OE_HOME/odoo-addons-enabled,$OE_HOME_EXT/addons' >> /etc/${OE_CONFIG}.conf"
else
    sudo su root -c "echo 'addons_path=$OE_HOME_EXT/addons,$OE_HOME/custom/addons,$OE_HOME/odoo-addons-enabled' >> /etc/${OE_CONFIG}.conf"
fi
	
echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/openerp-server --config=/etc/${OE_CONFIG}.conf' >> $OE_HOME_EXT/start.sh"
sudo chmod 755 $OE_HOME_EXT/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------

echo -e "* Create init file"
cat <<EOF > ~/$OE_CONFIG
#!/bin/sh
### BEGIN INIT INFO
# Provides: $OE_CONFIG
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Should-Start: \$network
# Should-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Enterprise Business Applications
# Description: Odoo + Clouder
### END INIT INFO
PATH=/bin:/sbin:/usr/bin
DAEMON=$OE_HOME_EXT/openerp-server
NAME=$OE_CONFIG
DESC=$OE_CONFIG
# Specify the user name (Default: odoo).
USER=$OE_USER
# Specify an alternate config file (Default: /etc/openerp-server.conf).
CONFIGFILE="/etc/${OE_CONFIG}.conf"
# pidfile
PIDFILE=/var/run/\${NAME}.pid
# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c \$CONFIGFILE"
[ -x \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0
checkpid() {
[ -f \$PIDFILE ] || return 1
pid=\`cat \$PIDFILE\`
[ -d /proc/\$pid ] && return 0
return 1
}
case "\${1}" in
start)
echo -n "Starting \${DESC}: "
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
stop)
echo -n "Stopping \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
echo "\${NAME}."
;;
restart|force-reload)
echo -n "Restarting \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
sleep 1
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
*)
N=/etc/init.d/\$NAME
echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
exit 1
;;
esac
exit 0
EOF

echo -e "* Security Init File"
sudo mv ~/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "* Change default xmlrpc port"
sudo su root -c "echo 'xmlrpc_port = $OE_PORT' >> /etc/${OE_CONFIG}.conf"

echo -e "* Start ODOO on Startup"
sudo update-rc.d $OE_CONFIG defaults

echo -e "* Starting Odoo Service"
sudo su root -c "/etc/init.d/$OE_CONFIG start"

echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "Port: $OE_PORT"
echo "User service: $OE_USER"
echo "User PostgreSQL: $OE_USER"
echo "Code location: $OE_USER"
echo "Addons folder: $OE_USER/$OE_CONFIG/addons/"
echo "Start Odoo service: sudo service $OE_CONFIG start"
echo "Stop Odoo service: sudo service $OE_CONFIG stop"
echo "Restart Odoo service: sudo service $OE_CONFIG restart"
echo "-----------------------------------------------------------"
