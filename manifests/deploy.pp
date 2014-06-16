class n1k-vem::deploy inherits n1k-vem {
  $n1kv_pkg = "nexus1000v"
  case $::osfamily {
    'Redhat': {
      $pkg_provider = "rpm"
      $libnl_pkg = "libnl"
      $ovs_pkg = "openvswitch"
      $puppet_file_uri = "puppet:///modules/n1k-vem/$imagename"
      $cmd_service = "/sbin/service"
    }
    'Ubuntu': {
      $pkg_provider = "dpkg"
      $libnl_pkg = "libnl1"
      $ovs_pkg = "openvswitch-switch"
      $puppet_file_uri = "puppet:///files/$imagename"
      $cmd_service = "/usr/sbin/service"
    }
    default: {
      fail( "${::osfamily} not yet supported by n1k-vem")
    }
  }

  package { "libnl":
    name => $libnl_pkg,
    ensure => "installed"
  }

  package { "openvswitch":
    name => $ovs_pkg,
    ensure => "installed"
  }

  file { "/etc/n1kv":
    owner => "root",
    group => "root",
    mode  => "664",
    ensure => directory,
  }

  if $vemimage_uri == 'local' {
    file { $imgfile:
      owner => "root",
      group => "root",
      mode => "666",
      source => $puppet_file_uri,
      require => File["/etc/n1kv"],
    }
    package {"nexus1000v":
      provider => $pkg_provider,
      name => $n1kv_pkg,
      ensure => "installed",
      source => $imgfile,
      require => File[$imgfile]
    }
  } else {
    yumrepo { "cisco-foreman":
      baseurl => $vemimage,
      descr => "Cisco Internal repo for Foreman",
      enabled => 1,
      gpgcheck => 1,
      gpgkey => "$vemimage/RPM-GPG-KEY"
      #proxy => "_none_",
    }
    package {"nexus1000v":
      name => $n1kv_pkg,
      ensure => $n1kv_pkgver,
    }
  }

  #specify template corresponding to 'n1kv.conf' and also 
  #the corresponding action when config file changes. 
  service { n1kv:
    ensure => running,
    restart => "$cmd_service n1kv restart"
  }

  file {"/etc/n1kv/n1kv.conf":
    owner => "root",
    group => "root",
    mode => "666",
    content => template('n1k-vem/n1kv.conf.erb'),
    require => Package["nexus1000v"],
    notify => Service[n1kv]
  }

  exec {"launch_vem":
    command => "$cmd_service n1kv start",
    unless => "/sbin/vemcmd show card"
  }

  if $isMultipleVtepInSameSubnet == 'true' {
    $my_sysctl_settings = {
      "net.ipv4.conf.default.rp_filter" => { value => 2 },
      "net.ipv4.conf.all.rp_filter" => { value => 2 },
      "net.ipv4.conf.default.arp_ignore" => { value => 1 },
      "net.ipv4.conf.all.arp_ignore" => { value => 1 },
      "net.ipv4.conf.all.arp_announce" => { value => 2 },
      "net.ipv4.conf.default.arp_announce" => { value => 2 },
    }

    create_resources(sysctl::value,$my_sysctl_settings)
  }

  Package["libnl"] -> Package["openvswitch"] -> File["/etc/n1kv"] -> Package["nexus1000v"] -> File["/etc/n1kv/n1kv.conf"] -> Exec["launch_vem"]
}
