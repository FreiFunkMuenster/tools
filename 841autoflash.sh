#!/bin/bash
IP=192.168.1.1
FLASHSIZE="16MB"

function test_last_command_successful () {
        if [[ $1 != "0" ]]
        then
            echo "Letzter Befehl fehlgeschlagen, Abbruch des Skripts."
        exit 1
    fi
}

if [ ! -d $(pwd)/841er-Images ]
then
    mkdir "$(pwd)/841er-Images"
fi
cd "$(pwd)/841er-Images"

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
        MAC=$(ssh -q -o "StrictHostKeyChecking=no" root@$IP "hexdump -s 0x0001FC00 -n6 /dev/mtd0 |cut -d' ' -f2-4 |tr -d ' '|head -n 1")
        test_last_command_successful $?
        echo "Die MAC Adresse lautet: $MAC"
        echo "Lese Hardware-ID..."
        HWID=$(ssh -q -o "StrictHostKeyChecking=no" root@$IP "hexdump -s 0x0001FD00 -n8 /dev/mtd0 |cut -d' ' -f2-5 |tr -d ' '|head -n 1")
        test_last_command_successful $?
        echo "Die Hardware-ID lautet: $HWID"
        echo "Lese ART Partition..."
        ssh -q -o "StrictHostKeyChecking=no" root@$IP 'cat /dev/$(cat /proc/mtd|grep art|cut -f1 -d":")' > artdump_${MAC}.bin
        test_last_command_successful $?

        hwversion=""

        case ${HWID:6:2} in
        "08")
            hwversion="v8"
            ;;
        "09")
            hwversion="v9"
            ;;
        "10")
            hwversion="v10"
            ;;
        "11")
            hwversion="v11"
            ;;
        esac

        if [[ $FLASHSIZE == "8MB" ]]
        then
            HWID=${HWID/084100/084108}
            COUNT_ZERO=2048
            SEEK_ART=2032
            FLASHSIZE_SMALL="8m"
        else
            HWID=${HWID/084100/084116}
            COUNT_ZERO=4096
            SEEK_ART=4080
            FLASHSIZE_SMALL="16m"
        fi
        echo "Hardware-ID angepasst. Sie lautet nun: $HWID"

        MAC_IN_HEX=""
        for((i=0;i<${#MAC};i+=2)); do MAC_IN_HEX=$MAC_IN_HEX\\x${MAC:$i:2}; done
        echo "MAC Adresse in HEX umgewandelt: $MAC_IN_HEX"
        HWID_IN_HEX=""
        for((i=0;i<${#HWID};i+=2)); do HWID_IN_HEX=$HWID_IN_HEX\\x${HWID:$i:2}; done
        echo "Hardware-ID in HEX umgewandelt: $HWID_IN_HEX"


        if [ ! -s uboot-tp-link-tl-wr841n-${hwversion}.bin ]
        then
            echo "Uboot-Abbild fehlt, lade es herunter."
            wget -nv -O uboot-tp-link-tl-wr841n-${hwversion}.bin http://derowe.com/u-boot/stable/tp-link-tl-wr841n-${hwversion}.bin;
            test_last_command_successful $?
        fi


        if [ ! -s gluon-tp-link-tl-wr841n-${FLASHSIZE_SMALL}-${hwversion}-sysupgrade.bin ]
        then
            echo "Gluon-Abbild fehlt, lade es herunter."
            wget -nv -O gluon-tp-link-tl-wr841n-${FLASHSIZE_SMALL}-${hwversion}-sysupgrade.bin http://firmware.ffmsl.de/841erupgrade/gluon---GenericFactoryImage-v0.1_Gluon-v2020.1.2-tp-link-tl-wr841n-nd-mod-${FLASHSIZE_SMALL}-${hwversion}-sysupgrade.bin;
            test_last_command_successful $?
        fi


        OUTFILE=newimage_${MAC}.bin

        dd status=none if=/dev/zero ibs=4k count=$COUNT_ZERO | LANG=C tr "\000" "\377" > "$OUTFILE"
        test_last_command_successful $?
        echo "Schreibe ART Partition ins Abbild..."
        dd status=none conv=notrunc obs=4k seek=$SEEK_ART if=artdump_${MAC}.bin of="$OUTFILE"
        test_last_command_successful $?
        echo "Schreibe Bootloader ins Abbild..."
        dd status=none conv=notrunc  if=uboot-tp-link-tl-wr841n-${hwversion}.bin of="$OUTFILE"
        test_last_command_successful $?
        echo "Schreibe Firmware ins Abbild..."
        dd status=none conv=notrunc obs=4k seek=32 if=gluon-tp-link-tl-wr841n-${FLASHSIZE_SMALL}-${hwversion}-sysupgrade.bin of="$OUTFILE"
        test_last_command_successful $?
        echo "Schreibe MAC Adresse ins Abbild..."
        printf $MAC_IN_HEX | dd status=none conv=notrunc ibs=1 obs=256 seek=508 count=8 of="$OUTFILE"
        test_last_command_successful $?
        echo "Schreibe Hardware-ID ins Abbild..."
        printf $HWID_IN_HEX | dd status=none conv=notrunc ibs=1 obs=256 seek=509 count=8 of="$OUTFILE"
        test_last_command_successful $?
        sync
        test_last_command_successful $?

        echo "Schreibe Abbild auf Flash..."
        flashrom -p ch341a_spi -w $OUTFILE
        test_last_command_successful $?

        echo "Lösche Abbild..."
        rm ${OUTFILE}

	read -s -n 1 -p "Bitte Taste drücken um mit dem nächsten Router fortzufahren..."
    fi
done
