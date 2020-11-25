#!/bin/sh

# run as root only
if [ $(id -u) -ne 0 ]; then
   echo "This script must be run as root"
   exit;
fi

filename=`realpath "${0}"`
scriptdir=`dirname "${filename}"`


# install some dependencies
pkg install bash

mv $scriptdir/wifi-watchdog.sh /usr/local/bin/
mv actions_wifi-watchdog.conf /usr/local/opnsense/service/conf/actions.d/

