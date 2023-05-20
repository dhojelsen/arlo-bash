#!/bin/bash

# determine subnet
SUBNET=$(/sbin/ip route | awk '/default/ { print $3 }' | cut -d. -f-3)

# ping all ips every 5 sevonds in the background
while true; do

	fping -gaq -i 1 -t 100 $SUBNET.0/24 &> /dev/null 
	sleep 5
done &
PID_FPING=$!

# kill fping on exit
trap "kill $PID_FPING" EXIT

# get commands
CMD_ARRIVE="$1"
shift
CMD_LEAVE="$1"
shift
ARR_MON=( "$@" )
ARR_MAC=()
MAC_PRESENT=0

while true; do
	for MAC in "${ARR_MON[@]}"; do
		# mac address is present
		if cat /proc/net/arp | tail -n +2 | grep $SUBNET | grep -q -i "$MAC" ; then

			# if macaddress is not in MAC, then it just arrived
			if [[ ! " ${ARR_MAC[*]} " =~ " ${MAC} " ]]; then
				
				echo "$MAC Arrived"
				# if ARR_MAC length is 0 then execute arrive command
				if [ "$MAC_PRESENT" -eq 0 ]; then
					echo "$($CMD_ARRIVE)"
				fi	
				ARR_MAC+=("$MAC")
				((MAC_PRESENT=MAC_PRESENT+1))
				
			fi
		else
		
			# if macaddress is in MAC, then it just left
			if [[ " ${ARR_MAC[*]} " =~ " ${MAC} " ]]; then
				
				echo "$MAC Left"
				# if ARR_MAC length is 1 then execute leave command
				if [ "$MAC_PRESENT" -eq 1 ]; then
					echo "$($CMD_LEAVE)";
				fi
				ARR_MAC=( "{ARR_MAC[@]/$MAC}" )	
				((MAC_PRESENT=MAC_PRESENT-1))
			fi

		fi	
	done
	sleep 5
done

