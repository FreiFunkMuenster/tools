#!/bin/bash

VERSION="10.2.0"
GLUON="v2023.2.5"
RELEASE="$GLUON+$VERSION"
IMGDIR="/home/ffmsl/firmware/output/multidomain/versions/v$VERSION/"
BRANCHES="experimental beta stable"

function notify () {
	MESSAGE=$1
	echo $MESSAGE
	if [[ -f "$HOME/ZULIP_AUTH_TOKEN" ]]; then
		curl --silent --output /dev/null https://zulip.ffmsl.de/api/v1/messages -u "firmware-bot@zulip.freifunk-muensterland.de:$(cat $HOME/ZULIP_AUTH_TOKEN)" -d "type=stream" -d "to=Firmware Log" -d "subject=Log-$(hostname)" -d "content=$MESSAGE" 2> /dev/null;
	fi
}

NUM_CORES_PLUS_ONE=$(expr $(nproc) + 1)
ANZAHLTARGETS=$(make list-targets | wc -l)

mkdir -p $IMGDIR

git checkout $GLUON

notify "Build $RELEASE make update gestartet."
make update

NUMTARGET=1
for TARGET in $(make list-targets); 
do
	notify "Build $RELEASE Target $TARGET ($NUMTARGET/$ANZAHLTARGETS) gestartet."
	make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=$TARGET GLUON_RELEASE=$RELEASE GLUON_IMAGEDIR=$IMGDIR
	let NUMTARGET++
done;
notify "Build $RELEASE abgeschlossen."

for BRANCH in $BRANCHES ;
do
	notify "Erstelle $BRANCH Manifest für Firmware $RELEASE."
	make manifest GLUON_RELEASE=$RELEASE GLUON_IMAGEDIR=$IMGDIR GLUON_AUTOUPDATER_BRANCH=$BRANCH
done;
notify "Manifeste fertig. :tada:"

#notify "Upload gestartet."
#rsync -lrtpEv /home/ffmsl/firmware/output/multidomain/versions/* root@firmware.ffmsl.de:/var/www/html/images/versions/
#notify "Upload abgeschlossen."
