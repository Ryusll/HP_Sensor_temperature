#!/bin/sh

date=`date +%Y%m%d%H%M`

#home_dir is this shell used user home directory
home_dir=/home/***

#your iLO ID, PW
hp_id=####
hp_pw=####

echo "Status,ServerName,iLOIP,Temperature" > $home_dir/temp_$date.csv

for ip in `cat /home/dcapuser/richard/temp_check.list`
do
	
	temp_check_ip=`awk -F"," '{print $1}' <<< $ip`
	temp_check_name=`awk -F"," '{print $2}' <<< $ip`
	temp_ilo=`sshpass -p$hp_pw ssh -o StrictHostKeyChecking=no -o LogLevel=quiet ${hp_id}@${temp_check_ip} -p22 "show /system1/sensor1/" | grep CurrentReading | awk -F"=" '{print $2}'`
	#temp > 42 = caution, temp > 45 = critical
	power_check=`sshpass -p$hp_pw ssh -o StrictHostKeyChecking=no -o LogLevel=quiet ${hp_id}@$temp_check_ip -p22 "show /system1" | grep enabledstat | awk -F"=" '{print $2}'`
	#enabled = power on, disabled = power off
	fan_check=`sshpass -p$hp_pw ssh -o StrictHostKeyChecking=no -o LogLevel=quiet ${hp_id}@${temp_check_ip} -p22 "show -a /system1/fan*" | grep DesiredSpeed | awk -F"=" '{print $2}' | awk '{print $1}'`
	if [[ $temp_ilo < 42 ]]
	then 
	T="Normal"
	elif [[ $temp_ilo > 42 ]] && [[ $temp_ilo < 45 ]]
	then
	T="Warning"
	elif [[ $temp_ilo > 45 ]]
	then
	T="Critical"
	fi;
		for fan in $fan_check
		do
		if [[ $fan -gt 70 ]]
		then
		fan="Warning"
		elif [[ $fan -lt 70 ]]
		then
		fan="OK"
		fi;
	done;
	if [[ $power_check == enabled* ]]
	then
	power_check="enabled"
	power="PowerOn"
	elif [[ $power_check == disabled* ]]
	then
	power_check="disabled"
	power="PowerOff"
	fi;

printf " [%9s] | %21s | %15s | %9s | %7s | %3s \n" $T $temp_check_name $temp_check_ip $power $fan $temp_ilo
printf "%s,%s,%s,%s\n" $T $temp_check_name $temp_check_ip $temp_ilo >> $home_dir/temp_$date.csv
done
exit
