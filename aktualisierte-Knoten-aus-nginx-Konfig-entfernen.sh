#!/bin/bash

while read line
do
	if [[ $line  == 2a03*/domaene[0-9][0-9]*/gluon-*sysupgrade* ]]
	then
		ipv6=${line%% *}
		echo Lösche: $ipv6
		sed -i "/$ipv6/d" /etc/nginx/sites-available/default.d/*
	fi
done < /var/log/nginx/access.log
systemctl reload nginx.service
	   
