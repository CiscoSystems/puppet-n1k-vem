class vem::generaten1kconf {

  $n1kconf = generate('/usr/bin/env', '/usr/share/puppet/modules/vem/bin/generateN1kConf.py', "-d${vem::compute::domainid}", "-i${vem::compute::vsmip}", "-m${vem::compute::ctrlmac}", "-e${vem::compute::hostmgmtint}", "-u${vem::compute::uplinkint}", "-psys-uplink", "-b${vem::compute::uvembrname}", "-v'vmknic-int1 profint mode dhcp mac 00:11:22:33:44:66, vmknic-int2 profint mode static address 192.168.1.91 netmask 255.255.255.0'" , "-f/tmp/${vem::compute::conftemplate}_n1k.conf")
  #$n1kconf = generate('/usr/bin/env', '/usr/share/puppet/modules/vem/bin/generateN1kConf.py', "-d${vem::compute::domainid}", "-i${vem::compute::vsmip}", "-m${vem::compute::ctrlmac}", "-e${vem::compute::hostmgmtint}", "-u${vem::compute::uplinkint}", "-psys-uplink", "-b${vem::compute::uvembrname}", "-v'vmknic-int1 profint mode dhcp mac 00:11:22:33:44:66, vmknic-int2 profint mode static address 192.168.1.91 netmask 255.255.255.0'" , "-f/etc/puppet/files/${vem::compute::conftemplate}_n1k.conf")

}
