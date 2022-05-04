#!/usr/bin/env python3

import libvirt
from FfDomain import FfDomain
import sys

libvcon = libvirt.open('qemu:///system')
testdeb = FfDomain(libvcon, "Testdebian")
testdeb.setNetwork('Clientnetz-' + sys.argv[1])
