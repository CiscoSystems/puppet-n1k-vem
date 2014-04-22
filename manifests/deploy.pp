class n1k-vem::deploy inherits n1k-vem {
  case $::osfamily {
    'Redhat': {
      $hgname = inline_template('<%= File.basename(hostgroup) %>')
      notify {"111message from here: $hgname $::hostgroup":}
      notify {"message from here: $imgfile $imagename $n1kconfname":}
      notify {"message from here: $n1kuplink_location $n1kuplinkintfile":}

      $pkg_provider = "rpm"
      $libnl_pkg = "libnl"
      $kernelheaders_pkg = "kernel-headers"
      $ovs_pkg = "openvswitch"
      $n1kv_pkg = "nexus_1000v_vem-6.5"  
      $puppet_file_loc = "modules/n1k-vem"
      $cmd_service = "/sbin/service"
    }
    'Ubuntu': {
      $pkg_provider = "dpkg"
      $libnl_pkg = "libnl1"
      $kernelheaders_pkg = "linux-headers-$::kernelrelease"
      $ovs_pkg = "openvswitch-switch"
      $n1kv_pkg = "nexus1000v"  
      $puppet_file_loc = "files"
      $cmd_service = "/usr/sbin/service"
    }
    default: {
      fail( "${::osfamily} not yet supported by puppet-vswitch")
    }
  }

  file {"/dev/kvm":
    owner => "root",
    group => "kvm",
    mode => "666",
  }

  package { "libnl":
    name => $libnl_pkg,
    ensure => "installed"
  }

  if $::osfamily == 'Ubuntu' {
    package {"build-essential":
      ensure => "installed"
    }
    file {"/etc/n1kv/modifyGroupOfDevKvm.py":
      owner => "root",
      group => "root",
      mode => "776",
      source => "puppet:///n1k-vem/modifyGroupOfDevKvm.py",
    }

    exec {"modifyGroupOfDevKvm.py":
      command => "/etc/n1kv/modifyGroupOfDevKvm.py"
    }
  }

  if ! defined(Package[$kernelheaders_pkg]) {
    package {"$kernelheaders_pkg":
      ensure => "installed"
    }
  }

  if ! defined(Package["openvswitch"]) {
    package { "openvswitch":
      name => $ovs_pkg,
      ensure => "installed"
    }
  }

  service { "n1kv":
    restart => "${cmd_service} n1kv restart"
  }

  file { "/etc/n1kv":
    owner => "root",
    group => "root",
    mode  => "664",
    ensure => directory,
    require => Package["libnl"],
  }


  if $vemimage_avail == 'local' {
    file { $imgfile:
      owner => "root",
      group => "root",
      mode => "666",
      source => "puppet:///${puppet_file_loc}/$imagename",
      require => File["/etc/n1kv"],
    }
    package {"nexus1000v":
      provider => $pkg_provider,
      name => $n1kv_pkg,
      ensure => latest,
      source => $imgfile,
      require => File[$imgfile]
    }
  } else {
    yumrepo { "cisco-foreman":
        baseurl => $vemimage,
        descr => "Internal repo for Foreman",
        enabled => 1,
        gpgcheck => 1,
        gpgkey => "$vemimage/RPM-GPG-KEY"
      #proxy => "_none_",
    }
    package {"nexus1000v":
      name => $n1kv_pkg,
      ensure => "installed",
    }
  }

  file {"/etc/n1kv/n1kv.conf":
    owner => "root",
    group => "root",
    mode => "666",
    source => "puppet:///${puppet_file_loc}/${n1kconfname}_n1k.conf",
    require => Package["nexus1000v"],
    notify => Service["n1kv"]
  }

  file { $n1kuplink_location:
    owner => "root",
    group => "root",
    mode => "666",
    source => "puppet:///${puppet_file_loc}/$n1kuplinkintfile",
    require => File["/etc/n1kv"],
  }

  exec {"bring_uplink":
    command => "/bin/sh $n1kuplink_location"
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

  if $::osfamily == 'Redhat' {
    Package["libnl"] -> Package[$kernelheaders_pkg] -> Package["openvswitch"] -> File["/etc/n1kv"] -> Package["nexus1000v"] -> File["/etc/n1kv/n1kv.conf"] -> File[$n1kuplink_location] -> Exec["bring_uplink"] -> Exec["launch_vem"]
    #Package["libnl"] -> Package[$kernelheaders_pkg] -> Package["openvswitch"] -> File["/etc/n1kv"] -> File[$imgfile] -> Package["nexus1000v"] -> File["/etc/n1kv/n1kv.conf"] -> File[$n1kuplink_location] -> Exec["bring_uplink"] -> Exec["launch_vem"]
  } elsif $::operatingsystem == 'Ubuntu' {
    Package["libnl"] -> Package["build-essential"] -> Package[$kernelheaders_pkg] -> Package["openvswitch"] -> File["/etc/n1kv"] -> File["/etc/n1kv/modifyGroupOfDevKvm.py"] -> Exec["modifyGroupOfDevKvm.py"] -> File[$imgfile] -> Package["nexus1000v"] -> File["/etc/n1kv/n1kv.conf"] -> File[$n1kuplink_location] -> Exec["bring_uplink"] -> Exec["launch_vem"]
  }
}
