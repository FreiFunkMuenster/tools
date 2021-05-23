#!/bin/ash

TARGET_IP="192.168.1.1"

configure_network () {
    ip a d 192.168.1.1/24 dev br-setup
    ip a a 192.168.1.2/24 dev br-setup
}

ping_target () {
    ping -c1 $TARGET_IP
    echo $?
}

wait_for_remote () {
    result=$(ping_target)
    while [[ "$result" == "1" ]]
    do
        echo "$TARGET_IP not reachable"
        sleep 1s
        result=$(ping_target)
    done
}

get_remote_ipv6_prefix () {
    echo $(ssh root@192.168.1.1 "grep -A1 'local_node_route6' /etc/config/network | tail -n1")
}

parse_domain_number () {
    remote_domain=$1
    remote_domain=${remote_domain##*2a03:2260:115:}}
    remote_domain=${remote_domain%%00:*}
    if [[ ${#remote_domain} -gt 0 && ${#remote_domain} -le 2 && $remote_domain -gt 0 && $a $remote_domain -lt 256 ]]
    then
        echo $remote_domain
    else
        echo "Domain could not be determined. Is the source router part of Freifunk Münsterland? Aborting."
        exit 1
    fi
}

is_generic_firmware () {
    firmware=$(cat /lib/gluon/release)
    if [[ $(expr match $firmware "GenericFactoryImage*") != 0 ]]
    then
        return 0
    else
        return 1
    fi
}

upgrade_firmware () {
    wget -O /tmp/firmware.bin http://firmware.freifunk-muensterland.de/domaene$1/versions/v7.0.1/sysupgrade/gluon-ffmsd$1-v2020.2%2B7.0.1-tp-link-tl-wr841n-nd-mod-16m-$2-sysupgrade.bin
    sysupgrade -n /tmp/firmware.bin
    
}

determine_revision () {
    HWID=$(hexdump -s 0x0001FD00 -n8 /dev/mtd0 |cut -d' ' -f2-5 |tr -d ' '|head -n 1)
    case ${HWID:6:2} in
        "08")
            echo "v8"
            ;;
        "09")
            echo "v9"
            ;;
        "10")
            echo "v10"
            ;;
        "11")
            echo "v11"
            ;;
    esac
}

configure_network
wait_for_remote
if is_generic_firmware
then
    prefix_slug=$(get_remote_ipv6_prefix)
    domain_number=$(parse_domain_number "$prefix_slug")
    revision=$(determine_revision)
    upgrade_firmware $domain_number $revision
else
    echo "not implemented yet"

fi


