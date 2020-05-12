#!/bin/bash
IP=192.168.1.1
FLASHSIZE="16MB"

while (true)
do
    clear
    echo "Bitte Router anschließen."
    ping -c1 $IP > /dev/null 2>&1
    if [ $? != 0 ]
    then
        sleep 1s
    else
        clear
        echo "Lese MAC Adresse..."
        MAC=$(ssh -o "StrictHostKeyChecking=no" root@$IP "hexdump -s 0x0001FC00 -n6 /dev/mtd0 |cut -d' ' -f2-4 |tr -d ' '|head -n 1")
        echo "Lese Hardware-ID..."
        HWID=$(ssh -o "StrictHostKeyChecking=no" root@$IP "hexdump -s 0x0001FD00 -n8 /dev/mtd0 |cut -d' ' -f2-5 |tr -d ' '|head -n 1")
        echo "Lese ART Partition..."
        ssh -o "StrictHostKeyChecking=no" root@$IP 'cat /dev/$(cat /proc/mtd|grep art|cut -f1 -d":")' > artdump_${MAC}.bin
        #ssh -o "StrictHostKeyChecking=no" root@$IP "cat /dev/mtd4" > artdump_${MAC}.bin

        echo
        echo "=============================="
        echo "MAC: $MAC"
        echo "HWID: $HWID"
        echo "=============================="
        echo

        model=""

        case ${HWID:6:2} in
        "08")
            model="tl-wr841n-v8"
            ;;
        "09")
            model="tl-wr841n-v9"
            ;;
        "10")
            model="tl-wr841n-v10"
            ;;
        "11")
            model="tl-wr841n-v11"
            ;;
        esac

        if [[ $FLASHSIZE == "8MB" ]]
        then
            HWID=${HWID/084100/084108}
            COUNT_ZERO=2048
            SEEK_ART=2032
        else
            HWID=${HWID/084100/084116}
            COUNT_ZERO=4096
            SEEK_ART=4080
        fi
        echo
        echo "Hardware-ID angepasst. Sie lautet nun: $HWID"

        MAC_FORMAT1=""
        for((i=0;i<${#MAC};i+=2)); do MAC_FORMAT1=$MAC_FORMAT1\\x${MAC:$i:2}; done


        if [ ! -s uboot-tp-link-${model}.bin ]
        then
            echo "Uboot-Abbild fehlt, lade es herunter."
            wget -nv -O uboot-tp-link-${model}.bin http://derowe.com/u-boot/stable/tp-link-${model}.bin;
        fi


        if [ ! -s gluon-tp-link-${model}-sysupgrade.bin ]
        then
            echo "Gluon-Abbild fehlt, lade es herunter."
            wget -nv -O gluon-tp-link-${model}-sysupgrade.bin http://firmware.ffmsl.de/841erupgrade/gluon-tp-link-${model}-sysupgrade.bin;
        fi


        OUTFILE=newimage_${MAC}.bin

        dd status=none if=/dev/zero ibs=4k count=$COUNT_ZERO | LANG=C tr "\000" "\377" > "$OUTFILE"
        echo "Schreibe ART Partition ins Abbild..."
        dd status=none conv=notrunc obs=4k seek=$SEEK_ART if=artdump_${MAC}.bin of="$OUTFILE"
        echo "Schreibe Bootloader ins Abbild..."
        dd status=none conv=notrunc  if=uboot-tp-link-${model}.bin of="$OUTFILE"
        echo "Schreibe Firmware ins Abbild..."
        dd status=none conv=notrunc obs=4k seek=32 if=gluon-tp-link-${model}-sysupgrade.bin of="$OUTFILE"
        echo "Schreibe MAC Adresse ins Abbild..."
        printf $MAC_FORMAT1 | dd status=none conv=notrunc ibs=1 obs=256 seek=508 count=8 of="$OUTFILE"
        echo "Schreibe Hardware-ID ins Abbild..."
        printf $HWID | dd status=none conv=notrunc ibs=1 obs=256 seek=509 count=8 of="$OUTFILE"
        sync

        echo "Schreibe Abbild auf Flash..."
        flashrom -p ch341a_spi -w $OUTFILE

        echo "Lösche Abbild..."
        rm ${OUTFILE}

	read -s -n 1 -p "Press any key to continue . . ."
    fi
done
