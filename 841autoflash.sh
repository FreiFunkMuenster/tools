#!/usr/bin/bash
IP=192.168.1.1
FLASHSIZE="16MB"

while (true)
do
    clear
    ping -c1 $IP
    if [ $? != 0 ]
    then
        sleep 1s
    else

        MAC=$(ssh root@$IP "hexdump -s 0x0001FC00 -n6 /dev/mtd0 |cut -d' ' -f2-4 |tr -d ' '|head -n 1")
        HWID=$(ssh root@$IP "hexdump -s 0x0001FD00 -n8 /dev/mtd0 |cut -d' ' -f2-5 |tr -d ' '|head -n 1")

        ssh root@$IP "cat /dev/$(cat /proc/mtd|grep art|cut -f1 -d':')" > artdump.bin

        clear
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
        echo "Hardware-ID angepasst. Sie lautet nun:"
        echo $HWID

        MAC_FORMAT1=""
        for((i=0;i<${#MAC};i+=2)); do MAC_FORMAT1=$MAC_FORMAT1\\x${MAC:$i:2}; done

        
        if [ ! -s uboot-tp-link-${model}.bin ]
        then
            echo "Uboot-Abbild fehlt, lade es herunter."
            wget -nv -O uboot-tp-link-${model}.bin http://derowe.com/u-boot/stable/tp-link-${model}.bin;
        fi


        if [ ! -s gluon-tp-link-${model}.bin ]
        then
            echo "Gluon-Abbild fehlt, lade es herunter."
            wget -nv -O gluon-tp-link-${model}.bin http://firmware.ffmsl.de/841erupgrade/gluon-tp-link-${model}-sysupgrade.bin;
        fi


	OUTFILE=$(mktemp newimage_${MAC}_XXXXXX --suffix=.bin)

        dd if=/dev/zero ibs=4k count=$COUNT_ZERO | LANG=C tr "\000" "\377" > "$OUTFILE"
        dd conv=notrunc obs=4k seek=$SEEK_ART if=artdump.bin of="$OUTFILE"
        dd conv=notrunc  if=uboot-tp-link-${model}.bin of="$OUTFILE"
        dd conv=notrunc obs=4k seek=32 if=gluon-tp-link-${model}.bin of="$OUTFILE"
        printf $MAC_FORMAT1 | dd conv=notrunc ibs=1 obs=256 seek=508 count=8 of="$OUTFILE"
        printf $HWID | dd conv=notrunc ibs=1 obs=256 seek=509 count=8 of="$OUTFILE"
        sync
        echo "Abbild auf Flash schreiben. (This could take a while...)"
        flashrom -p ch341a_spi -w $OUTFILE

	echo "Temp Abbild löschen."
	rm ${OUTFILE}
    fi
done
