#!/bin/bash

PRIORITY=0

cd $1
datum='2016-01-01 14:24:59+00:00'

for i in stable beta experimental; do
	echo "BRANCH=$i" > $i.manifest
	echo "DATE=$datum" >> $i.manifest
	echo "PRIORITY=$PRIORITY" >> $i.manifest
	echo >> $i.manifest
	for j in *bin; do
		model=${j#*-*-*-*}
		model=${model%-sysupgrade.bin}
		version=${j#*-*-}
		version=${version%-$model-sysupgrade.bin}
		version="v2018.2.2+9.9.9"
		pruefsumme256file=`sha256sum $j|sed -e 's/  / /g'`
		pruefsumme512file=`sha512sum $j|sed -e 's/  / /g'`
		pruefsumme256=`sha256sum $j|sed -e 's/ .*//'`
                pruefsumme512=`sha512sum $j|sed -e 's/ .*//'`
		originalFile=$(readlink -f $j)
		fileSize=$(stat -c %s "$originalFile")
		echo "$model $version $pruefsumme256 $fileSize $j" >> $i.manifest
		echo "$model $version $pruefsumme256 $j" >> $i.manifest
                echo "$model $version $pruefsumme512 $j" >> $i.manifest
		echo "$i $model $version"
	done
        for j in *tar; do
                model=${j#*-*-*-*}
                model=${model%-sysupgrade.tar}
                version=${j#*-*-}
                version=${version%-$model-sysupgrade.tar}
		version="v2018.2.2+9.9.9"
                pruefsumme256file=`sha256sum $j|sed -e 's/  / /g'`
                pruefsumme512file=`sha512sum $j|sed -e 's/  / /g'`
                pruefsumme256=`sha256sum $j|sed -e 's/ .*//'`
                pruefsumme512=`sha512sum $j|sed -e 's/ .*//'`
                originalFile=$(readlink -f $j)
                fileSize=$(stat -c %s "$originalFile")
		echo "$model $version $pruefsumme256 $fileSize $j" >> $i.manifest
                echo "$model $version $pruefsumme256" >> $i.manifest
                echo "$model $version $pruefsumme512" >> $i.manifest
		echo "$i $model $version"
        done
        for j in *img.gz; do
                model=${j#*-*-*-*}
                model=${model%-sysupgrade.img.gz}
                version=${j#*-*-}
                version=${version%-$model-sysupgrade.img.gz}
		version="v2018.2.2+9.9.9"
                pruefsumme256file=`sha256sum $j|sed -e 's/  / /g'`
                pruefsumme512file=`sha512sum $j|sed -e 's/  / /g'`
                pruefsumme256=`sha256sum $j|sed -e 's/ .*//'`
                pruefsumme512=`sha512sum $j|sed -e 's/ .*//'`
                originalFile=$(readlink -f $j)
                fileSize=$(stat -c %s "$originalFile")
		echo "$model $version $pruefsumme256 $fileSize $j" >> $i.manifest
                echo "$model $version $pruefsumme256" >> $i.manifest
                echo "$model $version $pruefsumme512" >> $i.manifest
		echo "$i $model $version"
        done
done

