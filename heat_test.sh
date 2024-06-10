#!/bin/sh

counter=0
delaytime=10
total_runtime=600 # 10 minutes

temperature_file="/sys/class/thermal/thermal_zone0/temp"

glmark2_prg="/usr/bin/glmark2-es2-wayland"
multicrunch_prg="./multicrunch"

logfile=`mktemp`
csvfile="${logfile}.csv"
logfile="${logfile}.log"

echo "Logging to $logfile"
echo "CSV at $csvfile"

if [ ! -x $glmark2_prg ]; then
	echo "Test program $glmark2_prg NOT found"
	exit 127
fi
if [ ! -x $multicrunch_prg ]; then
	echo "Test program $multicrunch_prg NOT found"
	exit 127
fi

$glmark2_prg --fullscreen > /dev/null &
gmark_pid=$!
$multicrunch_prg  > /dev/null &
multicrunch_pid=$!


prog_running=1
running=1

touch $logfile
tail -f $logfile &

csv_head="time,thermal,load_average,load_running"
echo $csv_head > $csvfile

while [ $running -eq 1 ]; do 

	cur_temp=`cat ${temperature_file}`
	cur_la=`cat /proc/loadavg`
	cur_uptime=`cat /proc/uptime | awk '{ print $1 }'`
	
	csv_line="${cur_uptime},${cur_temp},${cur_la},${prog_running}"
	echo $csv_line >> $csvfile
	
	echo "----------------------- $counter -----------------------" >> $logfile
	echo $csv_head >> $logfile
	echo
	echo $csv_line >> $logfile
	echo "=====================================================" >> $logfile
	sleep $delaytime
	counter=$(($counter + $delaytime))
	if [ $prog_running -eq 1 ]; then
		if [ ! -f /proc/${gmark_pid}/exe ]; then
			kill $multicrunch_pid
			prog_running=0
		fi
	fi
	if [ $counter -gt $total_runtime ]; then
		running=0
	fi
done
echo "Logging to $logfile"
echo "CSV at $csvfile"
