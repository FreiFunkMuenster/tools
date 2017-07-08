#!/usr/bin/python3.4

import sys
import urllib.request
import urllib.parse
import gzip
import os

DEFAULT_DESTINATION_PATH="/var/lib/libvirt/images"

def download_image_file(link):
   splits = sys.argv[1].split('/')
   n = len(splits)
   name = urllib.parse.unquote(splits[n-1])
   resultFilePath, responseHeaders = urllib.request.urlretrieve(sys.argv[1], name)

   inF = gzip.open(name, 'rb')
   outF = open(name.replace(".gz", ""), 'wb')
   outF.write( inF.read() )
   inF.close()
   outF.close()
   os.remove(name)


download_image_file(sys.argv[1])
   