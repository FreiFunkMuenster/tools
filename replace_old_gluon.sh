#!/bin/bash

virsh destroy $1
virsh undefine $1
rm /var/lib/libvirt/images/*$1*
./set_up_gluon.py $1
