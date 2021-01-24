#!/usr/local/bin/bash

## SETTINGS #######################################################
ifname="$1" 		#something like ath0_wlan1
ifnamehuman="$2" 	# the matching ifname from opnsense, like opt3
grace_period=$3 	# in seconds, 300s=5min
logfile="/var/log/wifi_watchdog.log"
uptimelogfile="/var/log/wifi_watchdog.log.uptime.csv"
dateformat="%d%b%y %H:%M:%S"
debug="false"
LOCKFILE="/tmp/`basename $0`.lock"
LOCKFD=99

#defaults just in case
[ -z "$ifname" ] && ifname="ath0_wlan1"
[ -z "$ifnamehuman" ] && ifnamehuman="opt3"
[ -z "$grace_period" ] && grace_period=60

## Insuring we run as root #######################################
if [ $(id -u) -ne 0 ]; then
   echo "This script must be run as root"
   exit 1;
fi



## LOCKFILE ######################################################
# PRIVATE
_lock()             { flock -$1 $LOCKFD; }
_no_more_locking()  { _lock u; _lock xn && rm -f $LOCKFILE; }
_prepare_locking()  { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _no_more_locking EXIT; }

# ON START
_prepare_locking

# PUBLIC
exlock_now()        { _lock xn; }  # obtain an exclusive lock immediately or fail
exlock()            { _lock x; }   # obtain an exclusive lock
shlock()            { _lock s; }   # obtain a shared lock
unlock()            { _lock u; }   # drop a lock


## LOGGING ########################################################
if [ "$debug" = "true" ]; then
	#set -x 
	true;
fi;

if [ ! -f $logfile ]; then
	echo $(date +"$dateformat")"-info: Wifi watchdog logfile initialized at "$(date +"$dateformat") > $logfile
fi

log() {
	if [ "$#" -gt 1 ]; then
		loglevel=$1
		shift
	else
		loglevel="info"
	fi
	case $loglevel in 
		debug)
			if [ "$debug" = "true" ]; then	
				echo $(date +"$dateformat")"-$loglevel : $@" >&2;
			fi;;
		info)
			echo $(date +"$dateformat")"-$loglevel:    $@" >> $logfile;;
		warning)
			echo $(date +"$dateformat")"-$loglevel: $@" >> $logfile;;
		error)
			echo $(date +"$dateformat")"-$loglevel:   $@" >> $logfile;;
		*)
			echo $(date +"$dateformat")"-debug : $@" >&2;;
	esac
}

# FUNCITONS ######################################################
nolock_exit() { 
	log error "Script started but the lockfile is still present, the script is still running. Exiting."
	exit 1;
}

get_status() {
	echo $(ifconfig $ifname | while read line; do echo "$line linebreak "; done;)
	# @todo we could try something cleaner here by parsing the json from this command for example
	# configctl interface show interfaces
}

get_linkstatus() {
	echo $1|grep status |sed -E '/ status:/!d;s/^.* status: ([^b]*) linebreak.*$/\1/g;s/linebreak//g'
}

get_ipv4() {
	echo $1 |sed -E '/ inet /!d;s/^.* inet ([^ ]+) netmask.*$/\1/g'
}

get_subnet() {
	echo $1 | sed -E '/ inet /!d;s/^.* netmask ([^ ]+) broadcast.*$/\1/g'
}

check_needtofix_reason() {
	local status=$(get_status) 					#;log debug "staus: $status";
	linkstatus=$(get_linkstatus "$status") 	; log debug linkstatus: $linkstatus
	ipv4=$(get_ipv4 "$status") 				; log debug current IP: $ipv4
	subnet=$(get_subnet "$status") 			; log debug current subnet: $subnet
	log info "$ifname status is '$linkstatus' with ip '$ipv4' netmask '$subnet'";
	needtofix=false
	reason=""
	# assessing if we need to do something ########
	if [ "$linkstatus" != "associated" ]; then
	    needtofix="true"
	    reason="status is not associated ($linkstatus)"
	    log warning "need to fix because $reason"
	else
	    if [ -z "$ipv4" ]; then
	        needtofix="true"
	        reason="there is not IPv4 despite the linke beeing associated"
	        log warning "need to fix because $reason"
	    fi
	fi
}

perform_fix_attempt() {
	log error "$reason";
	log info "$ifname status before fix_attempt was '$linkstatus' with ip '$ipv4' netmask '$subnet'";
	log info "reconfiguring interface to force the link to come up again";
	ifconfig $ifname >> $logfile
	configctl interface reconfigure $ifnamehuman;
}


perform_fix() {
	log error "$reason";
	log info "$ifname status before rebooting was '$linkstatus' with ip '$ipv4' netmask '$subnet'";
	log info "rebooting to force the link to come up again";
	ifconfig $ifname >> $logfile
	echo $(date +"$dateformat")";"$(uptime| awk -F'( |,|:)+' '{d=h=m=0; if ($7=="min") m=$6; else {if ($7~/^day/) {d=$6;h=$8;m=$9} else {h=$6;m=$7}}} {print d+0,"days,",h+0,"hours,",m+0,"minutes."}') >> $uptimelogfile
	reboot;
}



## MAIN SCRIPT ###################################################

exlock_now || nolock_exit

### old version without functions : BEGIN #####
#status=$(ifconfig $ifname | while read line; do echo "$line linebreak "; done;)
#linkstatus=$(echo $status|grep status |sed -E '/ status:/!d;s/^.* status: ([^ ]*) .*$/\1/g;s/linebreak//g');
#ipv4=$(echo $status|grep status |sed -E '/ inet /!d;s/^.* inet ([^ ]+) netmask.*$/\1/g');
#subnet=$(echo $status|grep status |sed -E '/ inet /!d;s/^.* netmask ([^ ]+) broadcast.*$/\1/g');
### old version without functions : END #######

# parse the current wifi status ##############


check_needtofix_reason

# trying to fix if needed ######################
if [ "$needtofix" = "true" ]; then
	perform_fix_attempt
	# waiting for grace period
	log warning "waiting for $grace_period seconds in the hope the interface recovers by itself..."
	sleep $grace_period
	# re-checking
	check_needtofix_reason
	if [ "$needtofix" = "true" ]; then
		perform_fix
	else
		log info "interface recovered before the end of the grace period. exiting gracefully";
		exit 0
	fi
else 
	log debug "all seems fine, doing nothing and going back to sleep.";
fi

exit 0
