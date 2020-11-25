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
mv $scriptdir/wifi-watchdog.sh /usr/local/bin/
chmod +x /usr/local/bin/wifi-watchdog.sh

echo "installing the cron task"
mv $scriptdir/actions_wifi-watchdog.conf /usr/local/opnsense/service/conf/actions.d/
chown root:wheels /usr/local/opnsense/service/conf/actions.d/actions_wifi-watchdog.conf

echo "done. It seems a reboot is necessary for the cron action to show up in the GUI."


