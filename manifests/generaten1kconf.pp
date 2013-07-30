class n1k-vem::generaten1kconf {

  $n1kconf = generate('/usr/bin/env', '/usr/share/puppet/modules/n1k-vem/bin/generateN1kConf.py', "-d${n1k-vem::compute::domainid}", "-i${n1k-vem::compute::vsmip}", "-m${n1k-vem::compute::ctrlmac}", "-e${n1k-vem::compute::hostmgmtint}", "-u${n1k-vem::compute::uplinkint}", "-p${n1k-vem::compute::profile}", "-b${n1k-vem::compute::uvembrname}", "-v${n1k-vem::compute::vtepconfig}" , "-f/etc/puppet/files/${n1k-vem::compute::n1kconfname}_n1k.conf")

}
