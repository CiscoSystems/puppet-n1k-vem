#!/usr/bin/python
import optparse, tempfile, shutil, subprocess

usage = "usage: %prog [options]"
parser = optparse.OptionParser(usage=usage)
parser.add_option("-d", "--domainId", help="domainId", dest="domainId")
parser.add_option("-i", "--ipAddr", help="vsmIpAddr", dest="vsmIpAddr")
parser.add_option("-m", "--macAddr", help="macAddr", dest="macAddr")
parser.add_option("-e", "--hostMgmtInt", help="hostMgmtInt", dest="hostMgmtInt")
parser.add_option("-u", "--uplinkCfg", help="uplinkCfg", dest="uplinkCfg")
parser.add_option("-b", "--bridgeName", help="bridgeName", dest="bridgeName")
parser.add_option("-v", "--vtepConfig", help="vtepConfig", dest="vtepConfig")
parser.add_option("-f", "--fileName", help="n1kConf fileName", dest="n1kConfFile")

(options, args) = parser.parse_args()

domainId = options.domainId
vsmIpAddr = options.vsmIpAddr
macAddr = options.macAddr
hostMgmtInt = options.hostMgmtInt
upLinkCfg = options.uplinkCfg
bridgeName = options.bridgeName
vtepConfig = options.vtepConfig
n1kConfFile = options.n1kConfFile

print "domainId " + domainId
print "vsmIpAddr " + vsmIpAddr
print "macAddr " + macAddr
print "hostMgmtInt " + hostMgmtInt
print "upLinkCfg " + upLinkCfg
print "bridgeName " + bridgeName
print "vtepConfig " + vtepConfig

class Command(object):
   """Run a command and capture it's output string, error string and exit status"""
   def __init__(self, command):
       self.command = command

   def run(self, shell=True):
       import subprocess as sp
       process = sp.Popen(self.command, shell = shell, stdout = sp.PIPE, stderr = sp.PIPE)
       self.pid = process.pid
       self.output, self.error = process.communicate()
       self.failed = process.returncode
       return self

   @property
   def returncode(self):
       return self.failed

def createN1kConfFile(domainId, vsmIpAddr, macAddr, hostMgmtInt, upLinkCfg, bridgeName, vtepConfig,n1kConfFile ):
    ovf_f = tempfile.NamedTemporaryFile(delete=False)
    ovf_int = tempfile.NamedTemporaryFile(delete=False)

    st_int = ""
    st = "\
# This is a sample N1KV configurtion(n1k.conf1) file.\n\
# <n1kv.conf> file contains all the configuration parameters for UVEM operation.\n\
# Please find below a brief explanation of these parameters and their meaning.\n\
# Optional Parameters and Default Values of parameters are explicitly stated.\n\
# Note:\n\
# a) Mandatory parameters are needed for proper UVEM operation.\n\
#   N1KV DP/DPA should start even if these are not specified. \n\
#   But there will be functional impact. For eg: in VSM connectivity \n\
# b)For most of the mandatory parameters, you can use 'vemcmd' configuration mode. \n\
#  But to be persistent, please edit this configuration file. \n\n\
         "
    st += "\n\
#\n\
# <vsm-connection-params> \n\
# \n\
# TAG: switch-domain \n\
# Description: \n\
# Optional: No \n\
# Default: 1 \n\
"
    st = st + "switch-domain %s\n\n" % (domainId)

    st +=  "\n\
#TAG: l3control-ipaddr \n\
#Description: IP Address of VSM's Control I/F \n\
# Optional: No \n\
# Default: n/a \n\
"
    st += "l3control-ipaddr %s\n" % (vsmIpAddr)

    st += "\n\
# TAG: system-primary-mac\n\
# Description: MAC address of VSM's Control I/F\n\
# Optional: No\n\
# Default: n/a\n\
"
    st += "system-primary-mac %s\n" % (macAddr)

    st += "\n\
# TAG: host-mgmt-intf\n\
# Description: Management interface of the Host\n\
# Optional: No (Even if not on N1KV, we need this\n\
#               for Host Identification on VSM).\n\
# Default: n/a\n\
"
    st += "host-mgmt-intf %s\n" % (hostMgmtInt)


    st +="\n\
#\n\
#<system-port-profile-Info>\n\
# Description:  System Port Profiles.\n\
# Optional: Yes (If there are no System Interfaces: Mgmt I/F etc)\n\
#\n\
#Trunk Profile Format\n\
#profile <name> trunk <vlan>\n\
#profile <name> native-vlan <vlan>\n\
#profile <name> mtu <mtu-size>\n\
#\n\
#Access Profile\n\
#profile <name> access <vlan>\n\
#profile <name> mtu <mtu-size>\n\
"

    st += "\n\
#<Port-Profile Mapping>\n\
# Description: Port-Profile mapping for all UVEM managed Interfaces.\n\
# Optional: Uplinks: NO. System-Veth: NO.\n\
#         : Non-System Veth: YES. (Assume it will be populated by 'libvirt')\n\
#\n\
# Format:\n\
# phys <port-name> profile  <profile-name>\n\
# virt <port-name> profile  <profile-name>\n\
# TBD: For uplinks UUID also need to be specified.\n\
"
    upLinkCfgDict = dict((key.strip(), value.strip()) for key,value in (item.split(':') for item in upLinkCfg.split(',')))
    for upLinkPort in upLinkCfgDict.iterkeys():
        st += "phys %s profile %s\n" % (upLinkPort, str(upLinkCfgDict.get(upLinkPort)))
        st_int += "ifconfig %s up\n" % upLinkPort


    st += "\n\
# <host-uuid>\n\
# Description: Host UUID\n\
# Optional : YES. If not specified UVEM would pick host UUID using 'dmidecode'.\n\
# host-uuid <host-uuid>\n\
\n\
# <dvswitch-uuid>\n\
# Description: N1KV DVS UUID. Not to be confused with Open VSwitch UUID\n\
# Optional : YES.\n\
# dvswitch-uuid <sw-uuid>\n\
\n\
# TBD\n\
# <log-path>\n\
# Description: Log Directory Path for DP/DPA\n\
# Optional: YES.\n\
# Default:\n\
# Format:\n\
# log-path:/opt/cisco/n1kv/logs\n\
\n\
# <uvem-ovs-brname>\n\
#\n\
# Description: Default Open VSwitch Bridge Name\n\
# Optional: YES.\n\
# Default: n1kvdvs\n\
# Format:\n\
"
    st += "uvem-ovs-brname %s\n" % (bridgeName)



    st += "\n\
# virt <port-name> profile <profile-name> [mode static|dhcp] [address <ipaddr>]\n\
#      [netmask <netmask ip>] [mac <00:11:22:33:44:55>]\n\
"
    for line in vtepConfig.split(','):
        st += line.strip() + "\n"

    ovf_f.write(st)
    ovf_f.close()
    cret = Command('sudo /bin/cp %s %s' % (ovf_f.name, n1kConfFile)).run()
    cret = Command('sudo /bin/chmod 766 %s' % n1kConfFile).run()

    st_int += "exit 0\n"
    ovf_int.write(st_int)
    ovf_int.close()
    cret_int = Command('sudo /bin/cp %s %s_uplink' % (ovf_int.name,n1kConfFile)).run()
    cret_int = Command('sudo /bin/chmod 766 %s_uplink' % n1kConfFile).run()

    return ovf_f

def main():
    ovf_f = createN1kConfFile(domainId, vsmIpAddr, macAddr, hostMgmtInt, upLinkCfg, bridgeName, vtepConfig, n1kConfFile)


if __name__ == "__main__":
    main()
