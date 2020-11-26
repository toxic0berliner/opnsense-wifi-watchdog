This aims to monitor a specific WLAN connection and try to keep ip up at almost all costs.

The idea comes from an opnSense system I manage remotely but that is only connected to the wider world through a WIFI connection, when it fails, I feel that only little effort is beeing made by opnSense to try to bring that connection up again, so I felt the need to regularly check the connectivity and try to act as best I could.

## Concept
The idea is quite simple :

- add a custom cron task that will run our script (inspired from [the official doc](https://docs.opnsense.org/development/backend/configd.html))
- schedule that task to run every 5 minutes (using GUI)
- have our script check the WIFI connection and try to fix it :
  1. check link status and IP
  1. try to reload the interface
  1. if it fails to bring it up, simply reboot the opnSense box.

## Install 
    cd /home/<your-user>/
    git clone <this repo url>
    chmod +x ./install.sh
    ./install.sh
Then in the GUI you should be able to ad a cron task selecting "Wifi watchdog" in the command dropdown and giving it 3 parameters :
 - the interface name as it show in ifconfig, should be something like ath0_wlan1
 - the matching interface name in the opnSense sense : something like opt3
 - the number of seconds to wait for an interface reconfigure to hopefully solve the link being down, after this wait if the interface is not up and connected the script will reboot the system. Typically 60 seconds is enought for what I see.