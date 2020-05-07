#!/usr/bin/bash
IP=192.168.1.1
FLASHSIZE="16MB"

OUTFILE=finaluboot.bin

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

        
        if [ ! -s ${model}.bin ]
        then
            echo "Uboot-Abbild fehlt, lade es herunter."
            wget -nv -O ${model}.bin http://derowe.com/u-boot/stable/tp-link-${model}.bin;
        fi
        cp tp-link-${model}.bin uboot.bin


        dd if=/dev/zero ibs=4k count=$COUNT_ZERO | LANG=C tr "\000" "\377" > "$OUTFILE"
        dd conv=notrunc obs=4k seek=$SEEK_ART if=artdump.bin of="$OUTFILE"
        dd conv=notrunc  if=uboot.bin of="$OUTFILE"
        # Hier noch überlegen, ob wir ein gluon mit draufspielen oder das sogar erforderlich is
        #dd conv=notrunc obs=4k seek=32 if=gluonsysupgrade.bin of="$OUTFILE"
        printf $MAC_FORMAT1 | dd conv=notrunc ibs=1 obs=256 seek=508 count=8 of="$OUTFILE"
        printf $HWID | dd conv=notrunc ibs=1 obs=256 seek=509 count=8 of="$OUTFILE"
        sync
        echo "Jetzt den Programmer starten..."
        echo "ch341a_spi ...parameter?"
    fi
done
