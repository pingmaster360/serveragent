#!/bin/bash
#
#////////////////////////////////////////////////////////////
#===========================================================
# Pingmaster - Installer v1.1
#===========================================================
# Set environment
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# Clear the screen
clear
#SERVERKEY=$1
#GATEWAY=$2
LOG=/tmp/pingmaster.log
echo "--------------------------------"
echo " WELCOME TO PING MASTER SERVER MONITORING AGENT INSTALLER"
echo "--------------------------------"
echo " "
# Are we running as root
if [ $(id -u) != "0" ]; then
        echo "You don't have root privileges!"
        echo "Try again with root privileges"
        echo "Stopping installation process"
        exit 1;
fi
# Is the server key parameter given ?
if [ $# -lt 1 ]; then
        echo "The server key is missing"
        echo "Stopping installation process"
        exit 1;
fi
echo "OK"
### install Dependencies
echo "Installing Dependencies"
# RHEL / CentOS / etc
if [ -n "$(command -v yum)" ]; then
        yum -y install cronie gzip curl >> $LOG 2>&1
        service crond start >> $LOG 2>&1
        chkconfig crond on >> $LOG 2>&1
        # Check if perl available or not
        if ! type "perl" >> $LOG 2>&1; then
                yum -y install perl >> $LOG 2>&1
        fi
        # Check if unzip available or not
        if ! type "unzip" >> $LOG 2>&1; then
                yum -y install unzip >> $LOG 2>&1
        fi
        # Check if curl available or not
        if ! type "curl" >> $LOG 2>&1; then
                yum -y install curl >> $LOG 2>&1
        fi
fi
# Debian / Ubuntu
if [ -n "$(command -v apt-get)" ]; then
        apt-get update -y >> $LOG 2>&1
        apt-get install -y cron curl gzip >> $LOG 2>&1
        service cron start >> $LOG 2>&1
        # Check if perl available or not
        if ! type "perl" >> $LOG 2>&1; then
                apt-get install -y perl >> $LOG 2>&1
        fi
        # Check if unzip available or not
        if ! type "unzip" >> $LOG 2>&1; then
                apt-get install -y unzip >> $LOG 2>&1
        fi
        # Check if curl available or not
        if ! type "curl" >> $LOG 2>&1; then
                apt-get install -y curl >> $LOG 2>&1
        fi
fi
# ArchLinux
if [ -n "$(command -v pacman)" ]; then
        pacman -Sy  >> $LOG 2>&1
        pacman -S --noconfirm cronie curl gzip >> $LOG 2>&1
        systemctl start cronie >> $LOG 2>&1
        systemctl enable cronie >> $LOG 2>&1
        # Check if perl available or not
        if ! type "perl" >> $LOG 2>&1; then
                pacman -S --noconfirm perl >> $LOG 2>&1
        fi
        # Check if unzip available or not
        if ! type "unzip" >> $LOG 2>&1; then
                pacman -S --noconfirm unzip >> $LOG 2>&1
        fi
        # Check if curl available or not
        if ! type "curl" >> $LOG 2>&1; then
                pacman -S --noconfirm curl >> $LOG 2>&1
        fi
fi
# OpenSuse
if [ -n "$(command -v zypper)" ]; then
        zypper --non-interactive install cronie curl gzip >> $LOG 2>&1
        service cron start >> $LOG 2>&1
        # Check if perl available or not
        if ! type "perl" >> $LOG 2>&1; then
                zypper --non-interactive install perl >> $LOG 2>&1
        fi
        # Check if unzip available or not
        if ! type "unzip" >> $LOG 2>&1; then
                zypper --non-interactive install unzip >> $LOG 2>&1
        fi
        # Check if curl available or not
        if ! type "curl" >> $LOG 2>&1; then
                zypper --non-interactive install curl >> $LOG 2>&1
        fi
fi
# Gentoo
if [ -n "$(command -v emerge)" ]; then
        # Check if crontab is present or not available or not
        if ! type "crontab" >> $LOG 2>&1; then
                emerge cronie >> $LOG 2>&1
                /etc/init.d/cronie start >> $LOG 2>&1
                rc-update add cronie default >> $LOG 2>&1
        fi
        # Check if perl available or not
        if ! type "perl" >> $LOG 2>&1; then
                emerge perl >> $LOG 2>&1
        fi
        # Check if unzip available or not
        if ! type "unzip" >> $LOG 2>&1; then
                emerge unzip >> $LOG 2>&1
        fi
        # Check if curl available or not
        if ! type "curl" >> $LOG 2>&1; then
                emerge net-misc/curl >> $LOG 2>&1
        fi
        # Check if gzip available or not
        if ! type "gzip" >> $LOG 2>&1; then
                emerge gzip >> $LOG 2>&1
        fi
fi
# Slackware
if [ -f "/etc/slackware-version" ]; then
        if [ -n "$(command -v slackpkg)" ]; then
                # Check if crontab is present or not available or not
                if ! type "crontab" >> $LOG 2>&1; then
                        slackpkg -dialog=off -batch=on -default_answer=y install dcron >> $LOG 2>&1
                fi
                # Check if perl available or not
                if ! type "perl" >> $LOG 2>&1; then
                        slackpkg -dialog=off -batch=on -default_answer=y install perl >> $LOG 2>&1
                fi
                # Check if unzip available or not
                if ! type "unzip" >> $LOG 2>&1; then
                        slackpkg -dialog=off -batch=on -default_answer=y install infozip >> $LOG 2>&1
                fi
                # Check if curl available or not
                if ! type "curl" >> $LOG 2>&1; then
                        slackpkg -dialog=off -batch=on -default_answer=y install curl >> $LOG 2>&1
                fi
                # Check if gzip available or not
                if ! type "gzip" >> $LOG 2>&1; then
                        slackpkg -dialog=off -batch=on -default_answer=y install gzip >> $LOG 2>&1
                fi
        else
                echo "Please install slackpkg and re-run installation."
                exit 1;
        fi
fi
# Is Cron available?
if [ ! -n "$(command -v crontab)" ]; then
        echo "Cron is required but we could not install it."
        echo "Exiting installer"
        exit 1;
fi
# Is CURL available?
if [  ! -n "$(command -v curl)" ]; then
        echo "CURL is required but we could not install it."
        echo "Exiting installer"
        exit 1;
fi
# Remove previous installation
if [ -f /opt/pingmaster/agent.sh ]; then
        # Remove folder
        rm -rf /opt/pingmaster
        # Remove crontab
        crontab -r -u pingmasteragent >> $LOG 2>&1
        # Remove user
        userdel pingmasteragent >> $LOG 2>&1
fi
# Check if the system can establish SSL connection
if curl --output /dev/null --silent --head --fail "https://node.pingmaster.net"; then
        ### Install ###
        mkdir -p /opt/pingmaster >> $LOG 2>&1
        wget -O /opt/pingmaster/agent.sh https://pingmaster.net/agent/agent.sh >> $LOG 2>&1
        echo "$1" > /opt/pingmaster/serverkey
        echo "https://node.pingmaster.net/agent.php" > /opt/pingmaster/gateway
        echo "SSL Connection Established..." >> $LOG 2>$1
else
        echo " "
        echo "==========:( Sorry! Cannot install pingmaster Agent :(=========="
        echo " "
        echo "Maybe you are using old OS which cannot establish SSL connection."
        echo "But still if you want to continue monitoring then your system data"
        echo "will be sent to pingmaster using HTTP protocol."
        echo " "
        read -n 1 -p "Do you want to continue? [Y/n] " reply;
        if [ ! "$reply" = "${reply#[Nn]}" ]; then
           echo ""
           echo ""
           echo "Terminated pingmaster agent installation."
           echo "If you think its an error contact support."
           echo ""
           echo ""
           exit 1;
        fi
        echo ""
        echo "Continuing installation with HTTP protocol..."
        echo ""
        ### Install ###
        mkdir /opt/pingmaster
        wget -O /opt/pingmaster/agent.sh https://pingmaster.net/agent/agent.sh
        echo "$1" > /opt/pingmaster/serverkey
        echo "https://node.pingmaster.net/agent.php" > /opt/pingmaster/gateway
fi
# Did it download ?
if ! [ -f /opt/pingmaster/agent.sh ]; then
        echo "Unable to install!"
        echo "Exiting installer"
        exit 1;
fi
useradd pingmasteragent -r -d /opt/pingmaster -s /bin/false >> $LOG 2>&1
groupadd pingmasteragent >> $LOG 2>&1
# Disable cagefs for Pingmaster
if [ -f /usr/sbin/cagefsctl ]; then
        /usr/sbin/cagefsctl --disable pingmasteragent >> $LOG 2>&1
fi
# Modify user permissions
chown -R pingmasteragent:pingmasteragent /opt/pingmaster && chmod -R 700 /opt/pingmaster >> $LOG 2>&1
# Configure cron
crontab -u pingmasteragent -l 2>/dev/null | { cat; echo "* * * * * bash /opt/pingmaster/agent.sh > /opt/pingmaster/cron.log 2>&1"; } | crontab -u pingmasteragent -

echo " "
echo "-------------------------------------"
echo " Installation Completed "
echo "-------------------------------------"
echo "Log: cat /tmp/pingmaster.log"
echo " "
echo "====== Uninstall instructions ======="
echo "Execute the command below to uninstall Pingmaster Agent from your server"
echo " "
echo "-------------------------------------"
echo "rm -rf /opt/pingmaster && crontab -r -u pingmasteragent >> /tmp/pingmaster.log 2>&1 && userdel pingmasteragent >> /tmp/pingmaster.log 2>&1"
echo "-------------------------------------"
echo " "
echo "pingmaster.net"
echo "Thank you for choosing Pingmaster!"
# Attempt to delete this installer
if [ -f $0 ]; then
        rm -f $0
fi
