#!/bin/sh
# benötigt:
#	- sshfs
#	- ecdsautils (https://github.com/tcatm/ecdsautils)
#	- sign.sh und sigtest.sh aus dem Gluon Repo (https://github.com/freifunk-gluon/gluon/tree/master/contrib)

PUBLIC_SIG_KEY='xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
PATH_TO_SECRET_SIG_KEY='/root/secret'
FIRMWARESERVER_HOST='root@firmware.ffmsl.de'
FIRMWARESERVER_PORT='22'
FIRMWARESERVER_MOUNTPOINT='/media/firmware'

read -p "Version?: " VERSION
read -p "Branches? [alle]: " BRANCHES
read -p "Domänen? [alle]: " DOMAENEN

if [ "$DOMAENEN" = "" ] ; then
	DOMAENEN="$(seq -w 01 05) $(seq -w 07 76)"
fi

if [ "$BRANCHES" = "" ] ; then
        BRANCHES='experimental beta stable'
fi

mkdir -p $FIRMWARESERVER_MOUNTPOINT
sshfs -p $FIRMWARESERVER_PORT $FIRMWARESERVER_HOST:/ $FIRMWARESERVER_MOUNTPOINT

for b in $BRANCHES
do
        for i in $DOMAENEN
        do
		sign.sh $PATH_TO_SECRET_SIG_KEY $FIRMWARESERVER_MOUNTPOINT/var/www/html/domaene"$i"/versions/v"$VERSION"/sysupgrade/"$b".manifest
		sigtest.sh $PUBLIC_SIG_KEY $FIRMWARESERVER_MOUNTPOINT/var/www/html/domaene"$i"/versions/v"$VERSION"/sysupgrade/"$b".manifest

		RESULT=$?

		if [ $RESULT -eq 1 ] ; then
			echo "Signieren von Version $VERSION $b für Domäne-$i fehlgeschlagen!";
		elif [ $RESULT -eq 0 ] ; then
			echo "Signieren von Version $VERSION $b für Domäne-$i erfolgreich!";
		else
			echo "Signieren von Version $VERSION $b für Domäne-$i fehlgeschlagen mit Fehlercode $? !";
		fi
        done
done

fusermount -u $FIRMWARESERVER_MOUNTPOINT
