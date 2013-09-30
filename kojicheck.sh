#!/bin/bash
# Determine whether a koji builder should be rebooted based on checkin time

# Temp host file
hostfile="/tmp/hosts.html"

# Get enabled koji hosts
rm ${hostfile}
wget -O $hostfile http://koji.pidora.ca/koji/hosts

# Set counter
count=1
reset="false"

# I'm sorry if someone has to read|modify this. It greps for koji host names and the checkin times, then removes html 
# on both. It will then pass each hostname and checkin time through the loop, first hostname followed next by 
# that hostname's checkin time. 
# odd counter = hostname
# even counter = checkin time

echo "[running]"
date

for line in $(grep '<td><a href="hostinfo?hostID=[0-9]*">.*</a></td>.*$\|^.*[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].*$' /tmp/hosts.html | sed 's|^.*<td><a href="hostinfo?hostID=[0-9]*">\(.*\)</a></td>|\1|' | sed 's|^.*<td>\(....-..-..\) \(..:..:..\)</td>|\1\|\2|'); do
	# Check if counter is odd or even
	oddeven=$((${count}%2))
	count=$((count+1))
	
	if [[ ${oddeven} -eq 1 ]]; then
		# Hostname
		echo -n "Hostname = ${line}"
		hostname=${line}
	else
		# Checkin time format - 2013-08-20|13:30:00
		checkindate=$(echo "${line}" | cut -d'|' -f1)
		checkintime=$(echo "${line}" | cut -d'|' -f2)
		
		checkinyear=$(echo "${line}" | cut -d'|' -f1| cut -d'-' -f1)
		checkinmonth=$(echo "${line}" | cut -d'|' -f1| cut -d'-' -f2)
		checkinday=$(echo "${line}" | cut -d'|' -f1| cut -d'-' -f3)
		checkinhour=$(echo "${line}" | cut -d'|' -f2| cut -d':' -f1)
		checkinminute=$(echo "${line}" | cut -d'|' -f2| cut -d':' -f2)

		year=$(date +'%Y')
		month=$(date +'%m')
		day=$(date +'%d')
		hour=$(date +'%H')
		minute=$(date +'%M')
		
		# Convert time month day hour minute into minutes for comparison of 2 times
		checkinminutes=$(echo "(${checkinmonth}*30*24*60) + (${checkinday}*24*60) + (${checkinhour}*60) + ${checkinminute}"| bc)
		minutes=$(echo "(${month}*30*24*60) + (${day}*24*60) + (${hour}*60) + ${minute}" | bc)
		diff=$(echo "${minutes} - ${checkinminutes}" | bc)

		# Print info and a difference between times
		echo -n "|date = ${checkindate}|time = ${checkintime}|diff = ${diff}| " 
		
		# Compare times to see if the builder has not checked in for 2 hours
		if [[ ${diff} -gt 120  ]]; then
			echo "Failed - reseting koji on ${hostname}"
			ssh ${hostname} "chroot /root/f18v6/ /koji_restart.sh 2> /dev/null"
		else
			echo "Success"
		fi
	fi
done


