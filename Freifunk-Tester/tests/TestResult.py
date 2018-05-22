import os
class TestResult(object):
    def __init__(self, passed, short_description, benchmark_description, benchmark_number, testDescription, rawOutput, icinga_service, domain="unknown", gateway="random", optionalStuff=None):
        self.__passed = passed
        self.__benchmark_number = benchmark_number
        self.__testDescription = testDescription
        self.__rawOutput = rawOutput
        self.__optionalStuff = optionalStuff 
        self.__benchmark_description = benchmark_description
        self.__short_description = short_description
        self.__domain=domain
        self.__gateway=gateway
        self.__icinga_service = icinga_service 

    def passed(self):
        return self.__passed

    def benchmark(self):
        return self.__benchmark_number

    def testDescription(self):
        return self.__testDescription

    def getRawOutput(self):
        return self.__rawOutput

    def getOptionalStuff(self):
        return self.__optionalStuff

    def report(self):
        if self.passed():
            return '[passed] Domain: ' + self.__domain + ', Gateway: ' + self.__gateway + ", " + self.__short_description + ', ' + self.__benchmark_description + ': ' + str(self.__benchmark_number)
        else:
            return '[failed] Domain: ' + self.__domain + ', Gateway: ' + self.__gateway + ", " + self.__short_description + ', ' + self.__benchmark_description + ': ' + str(self.__benchmark_number) + ', test description: ' + self.__testDescription + ', raw output: ' + bytes.join(b'', self.__rawOutput).decode('utf-8')

    def print_report(self):
        print(self.report())

    def output_to_file(self, filename):
        fileobject = open(filename, 'w')
        if self.passed():
             fileobject.write('0\n')
        else:
             fileobject.write('1\n')
        fileobject.write(self.report())
        fileobject.close()

    def report_to_icinga(self):
        servicename = self.__domain + '%20' + self.__icinga_service 
        if self.passed():
             exit_status = '0'
             plugin_output = 'ok: ' + self.__short_description + ', ' + self.__benchmark_description + ': ' + str(self.__benchmark_number)
        else:
             exit_status = '1'
             plugin_output = 'failed: ' + self.__short_description + ', ' + self.__benchmark_description + ': ' + str(self.__benchmark_number)

        curl_command = '''curl -k -s -u $(cat /root/ICINGA_AUTH) -H 'Accept: application/json' -X POST 'https://icinga.freifunk-muenster.de:5665/v1/actions/process-check-result?service=remue!''' + servicename + '''' -d "{ \\\"exit_status\\\": ''' + exit_status + ''', \\\"plugin_output\\\": \\\"''' + plugin_output + '''\\\" }"'''
        #print(curl_command)
        os.system( curl_command )
        print('')
       



 