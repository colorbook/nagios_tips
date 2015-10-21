#!/bin/bash

# Title:    Nagios Plugin to check nagios client snort service.
# History:
# Date,         Time,   Author, Version,    Description.
# 2015/10/16,   20:30,  CCC,    v1,         Created Plugin.
# REFERENCE:
#   https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/3/en/pluginapi.html

#!/bin/bash

# Get host ip and setting check snort service(defaults  number of snort service is 2),
# and supervisor automatically run snort service.
host_ip=$1
num_check_srv=$(sudo ssh root@$host_ip "supervisorctl status|grep snort|grep RUNNING|wc -l")

# Check supervisor service.
if sudo ssh root@$host_ip "ps ax|grep -v grep|grep supervisord >> /dev/null";then
    # Check snort service.
    if [ $num_check_srv == 2 ];then
        echo "OK- snort service is OK!"
        exit 0
        
    elif [ $num_check_srv == 1 ];then
        echo "WARNING- snort service is not all running!|Restart snort service."
        sudo ssh root@$host_ip "supervisorctl reload"
        exit 1

    elif [ $num_check_srv == 0 ];then
        echo "CRITICAL- snort service is down!|Restart snort service."
        sudo ssh root@$host_ip "supervisorctl reload"
        exit 2

    else
        echo "UNKNOWN- something wrong!"
        exit 3
    fi

else
    echo "CRITICAL- supervisor service is down!|Restart supervosor service."
    sudo ssh root@$host_ip "supervisord;supervisorctl start"
    exit 2
fi
