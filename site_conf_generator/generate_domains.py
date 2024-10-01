#!/usr/bin/python
import jinja2
import csv

templateLoader = jinja2.FileSystemLoader(searchpath="./")
templateEnv = jinja2.Environment(loader=templateLoader)
TEMPLATE_FILE = "domain.j2"
template = templateEnv.get_template(TEMPLATE_FILE)

domain_array = []

with open('domains.csv', newline='') as csvfile:
    spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
    first_row_array = None
    for row in spamreader:
        if first_row_array == None:
            first_row_array = row
            continue
        domain_dict = {}
        for key in first_row_array:
            domain_dict[key] = row[len(domain_dict.keys())]
        domain_array.append(domain_dict)

for domain in domain_array:
    outputText = template.render(domain_data = domain)
    with open('{}.conf'.format(domain["site_code"]), "w") as out_file:
        out_file.write(outputText)
        out_file.close()
