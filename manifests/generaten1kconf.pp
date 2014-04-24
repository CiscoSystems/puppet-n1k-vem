class n1k-vem::generaten1kconf inherits n1k-vem {

  if $::osfamily == 'Ubuntu' {
    $n1kconf = generate('/usr/bin/env', '/usr/share/puppet/modules/n1k-vem/bin/generateN1kConf.py', "-d${n1k-vem::n1kv_vsm_domain_id}", "-i${n1k-vem::n1kv_vsm_ip}", "-e${n1k-vem::host_mgmt_intf}", "-u${n1k-vem::uplink_profile}", "-b${n1k-vem::uvembrname}", "-v${n1k-vem::vtep_config}" , "-f/etc/puppet/files/${n1k-vem::n1kconfname}_n1k.conf", "-t${n1k-vem::node_type}")
  } elsif $::osfamily == 'Redhat' {
    $n1kconf = generate('/usr/bin/env', '/usr/share/openstack-foreman-installer/puppet/modules/n1k-vem/bin/generateN1kConf.py', "-d${n1kv_vsm_domain_id}", "-i${n1kv_vsm_ip}", "-e${host_mgmt_intf}", "-u${uplink_profile}", "-b${uvembrname}", "-v${vtep_config}" , "-f${puppet_file_location}/${n1kconfname}_n1k.conf", "-t${node_type}")
  }

}
