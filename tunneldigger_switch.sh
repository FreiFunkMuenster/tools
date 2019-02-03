#!/bin/sh
alt=$(uci show tunneldigger|grep mesh_vpn|grep enabled)
alt=${alt:31:1}
echo $alt
 
change_if_necessary () {
    if [ "$alt" != "$1" ]
    then
        echo "Umschalten"
        uci set tunneldigger.@broker[0].enabled="$1"
        /etc/init.d/tunneldigger restart
    else
        echo "Nichts zu tun"   
    fi
}

count=$(batctl o | grep "[ \*] $(batctl gwl | grep -oE "\* [^ ]+" | grep -oE "[a-f0-9\:]+" || echo offline)" | grep -oE "\((1[5-9][0-9]|2[0-9]{2})\)" | wc -l)
if [[ $count -lt 1 ]]
then
    echo "VPN ein"
    change_if_necessary 1
elif [[ $count -gt 1 ]]
then
    echo "VPN aus"
    change_if_necessary 0
else
    echo "Tue nichts"
fi
