#!/bin/bash

host_ip=$1
log_num_file='/var/log/NUM_OF.log'
num_no_log=0
num_nowlogs=$(sudo ssh root@$host_ip "grep iptables /var/log/messages| wc -l")
num_pastlogs=$(sudo ssh root@$host_ip "cat $log_num_file")

if [ $num_nowlogs == $num_no_log ]; then
    echo "CRITICAL-HAVENT GOT ANY LOG TODAY.| NOW:$num_nowlogs PAST:$num_pastlogs"
    sudo ssh root@$host_ip "echo $num_nowlogs > $log_num_file"
    exit 2

elif [ $num_nowlogs -eq $num_pastlogs ]; then
    echo "WARNING-NO LOGS DURING CHECK POINTS.| NOW:$num_nowlogs PAST:$num_pastlogs"
    sudo ssh root@$host_ip "echo $num_nowlogs > $log_num_file"
    exit 1

elif [ $num_nowlogs -gt $num_pastlogs ]; then
    echo "OK-NEW LOGS LOGGED.| NOW:$num_nowlogs PAST:$num_pastlogs"
    sudo ssh root@$host_ip "echo $num_nowlogs > $log_num_file"
    exit 0

else
    echo "UNKNOWN-SOMETHING WRONG.| NOW:$num_nowlogs PAST:$num_pastlogs"
    sudo ssh root@$host_ip "echo $num_nowlogs > $log_num_file"
    exit 3
fi
