#!/bin/bash

# Title:    Nagios Plugin to check name which no data over 3 days in DB.
# History:
# Date,         Time,   Author, Version,    Description.
# 2015/10/16,   19:33,  CCC,    v1,         Created Plugin.
# REFERENCE:
#   https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/3/en/pluginapi.html

# Variable of database
DBNAME="DBNAME"
USERNAME="USERNAME"
IP=10.10.10.10
STARTDATE=$(date --date='3 days ago' +%Y-%m-%d)
ENDDATE=$(date +%Y-%m-%d)
ACCOUNT=$(sudo psql -d $DBNAME -U $USERNAME -h $IP -w -c \
    "COPY (SELECT username FROM accounts) TO STDOUT WITH CSV")

# Variable of name
list_nodata_name=""
num_nodata_name=0

# Find out no data over 3 day name in DB
for name in ${ACCOUNT[@]}; do
    exits=$(sudo psql -d $DBNAME -U $USERNAME -h $IP -w -c \
    "select exists ( \
        SELECT * FROM table WHERE tstamp >= '$STARTDATE' \
        AND tstamp <= '$ENDDATE' \
        AND username = '$name');" |grep -E '(t|f)')

    if [ $exits  = "f" ]; then
        list_nodata_name+="$name "
        ((num_nodata_name+=1))
    fi
done

# Nagios status
if [ $num_nodata_name -lt 10 ]; then
    echo "OK- $num_nodata_name over 3 days no data.|$list_nodata_name"
    exit 0

elif [ $num_nodata_name -gt 10 ] && [ $num_nodata_name -lt 25 ]; then
    echo "WARNING- $num_nodata_name over 3 days no data.|$list_nodata_name"
    exit 1

elif [ $num_nodata_name -gt 25 ]; then
    echo "CRITICAL- $num_nodata_name over 3 days no data.|$list_nodata_name"
    exit 2

else
    echo "UNKNOWN- Something wrong.|num_nodata_name: $num_nodata_name"
    exit 3

fi
