This aims to monitor a specific WLAN connection and try to keep ip up at almost all costs.

The idea comes from an opnSense system I manage remotely but that is only connected to the wider world through a WIFI connection, when it fails, I feel that only little effort is beeing made by opnSense to try to bring that connection up again, so I felt the need to regularly check the connectivity and try to act as best I could.

## Concept
The idea is quite simple :

- add a custom cron task that will run our script (inspired from [https://docs.opnsense.org/development/backend/configd.html|the official doc])
- schedule that task to run every 5 minutes (using GUI)
- have our script check the WIFI connection and try to fix it :
  1. check link status and IP
  1. try to reload the interface
  1. if it fails to bring it up, simply reboot the opnSense box.

## Install 
    cd /home/<your-user>/
    git clone <this repo url>
    ./install.sh #(we'll see if I go that far...)
