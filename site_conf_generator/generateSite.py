import csv
import re
import fileinput
from shutil import copyfile

with open('domains.csv', newline='') as csvfile:
    domainDB = csv.reader(csvfile)
    next(domainDB, None)
    for row in domainDB:
        domainNumb = row[0]
        githubNumb = row[1]
        domainName = row[2]
        publicName = row[3]
        internName = row[4]
        domainSeed = row[5]
        ipv4Prefix = row[6]
        oldipv6Prefix = row[7]
        ipv6Prefix = row[8]
        meshid = row[9]
        print("Generiere Domain-Nummer" + domainNumb)
        print("     Domain-Name :" + domainName)
        print("     Public-Name :" + publicName)
        print("     Intern-Name :" + internName)
        print("     Domain-Seed :" + domainSeed)
        print("     IPv4-Prefix :" + ipv4Prefix)
        print("     IPv6-Prefix :" + ipv6Prefix)
        print(" Alt-IPv6-Prefix :" + oldipv6Prefix)
        print("         Mesh-ID :" + meshid)
        print("____________________________________________")
        copyfile('site.pattern', internName + ".conf")
        with open(internName + ".conf") as file:
            replaced = file.read().replace("__MESHID__", meshid).replace("__NUM__", domainNumb).replace("__SITENAME__", publicName).replace("__SITECODE__", internName).replace("__DOMAINSEED__", domainSeed).replace("__V4PRE__", ipv4Prefix).replace("__V6PRE__", ipv6Prefix).replace("__OLDV6PRE__", oldipv6Prefix).replace("__DOMAENE__", domainName)
        with open(internName + ".conf", "w") as f:
            f.write(replaced)
