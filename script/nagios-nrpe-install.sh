#!/bin/sh

set -e  # stop when error occurs
set -x  # show progress

# nagios-nrpe-plugin pachage for nagios proxy client to use check_nrpe
necessary_packages=( 
	"openssl" \
	"nagios-nrpe-server" \
	"nagios-plugins" \
	"nagios-nrpe-plugin"
)

# Update the Package Index
    apt-get update

# Install necessary packages
    echo "Installing necessary packages ..."
        for pkg in ${necessary_packages[*]}
        do
            apt-get -y install $pkg
        done
    echo "Packages installation is done ..."

# Setting allow nagios server host(10.10.10.10)
	echo "Setting allow nagios server host ..."
		sed -i 's/allowed_hosts.*$/allowed_hosts=127.0.0.1,10.10.10.10/g' /etc/nagios/nrpe.cfg
	echo "Setting allow nagios server host is done ..."

# Setting firewall rule
	echo "Setting firewall rule ..."
		iptables -t filter -A INPUT -s 10.10.10.10 -p tcp --dport 5666
	echo "Setting firewall rule is done ..."

