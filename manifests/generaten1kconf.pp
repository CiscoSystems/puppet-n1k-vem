class n1k-vem::generaten1kconf {

  $n1kconf = generate('/usr/bin/env', '/usr/share/puppet/modules/n1k-vem/bin/generateN1kConf.py', "-d${n1k-vem::domainid}", "-i${n1k-vem::vsmip}", "-m${n1k-vem::ctrlmac}", "-e${n1k-vem::hostmgmtint}", "-u${n1k-vem::uplinkint}", "-p${n1k-vem::profile}", "-b${n1k-vem::uvembrname}", "-v${n1k-vem::vtepconfig}" , "-f/etc/puppet/files/${n1k-vem::n1kconfname}_n1k.conf")

}
