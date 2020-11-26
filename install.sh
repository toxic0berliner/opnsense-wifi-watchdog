#!/bin/sh

# run as root only
if [ $(id -u) -ne 0 ]; then
   echo "This script must be run as root"
   exit;
fi

filename=`realpath "${0}"`
scriptdir=`dirname "${filename}"`


echo "install some dependencies : bash"
pkg install bash

echo "installing our script"
mv $scriptdir/wifiwatchdog.sh /usr/local/bin/
chmod +x /usr/local/bin/wifiwatchdog.sh
chown root:wheel /usr/local/bin/wifiwatchdog.sh

echo "installing the cron task"
mv $scriptdir/actions_wifiwatchdog.conf /usr/local/opnsense/service/conf/actions.d/
chown root:wheel /usr/local/opnsense/service/conf/actions.d/actions_wifiwatchdog.conf

echo "restarting the configd service"
service configd restart

echo "done."
echo "You can now add a cron task in the GUI."


