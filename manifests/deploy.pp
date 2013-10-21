class n1k-vem::deploy {

  package { "libnl1":
    name => "libnl1",
    ensure => "installed"
  }

  package {"build-essential":
    ensure => "installed"
  }

  $kernelheaders_pkg = "linux-headers-$::kernelrelease"
  if ! defined(Package[$kernelheaders_pkg]) {
    package {"$kernelheaders_pkg":
      ensure => "installed"
    }
  }

  if ! defined(Package["openvswitch-switch"]) {
    package { "openvswitch-switch":
      ensure => "installed"
    }
  }

  service { "n1kv":
    restart => "/usr/sbin/service n1kv restart"
  }

  file { "/etc/n1kv":
    owner => "root",
    group => "root",
    mode  => "664",
    ensure => directory,
    require => Package["libnl1"],
  }

  file { $imgfile:
    owner => "root",
    group => "root",
    mode => "666",
    source => "puppet:///files/$imagename",
    require => File["/etc/n1kv"],
  }

  package {"nexus1000v":
    provider => dpkg,
    ensure => latest,
    source => $imgfile,
    require => File[$imgfile]
  }

  file {"/etc/n1kv/n1kv.conf":
    owner => "root",
    group => "root",
    mode => "666",
    source => "puppet:///files/${n1kconfname}_n1k.conf",
    require => Package["nexus1000v"],
    notify => Service["n1kv"]
  }

  file { $n1kuplink_location:
    owner => "root",
    group => "root",
    mode => "666",
    source => "puppet:///files/$n1kuplinkintfile",
    require => File["/etc/n1kv"],
  }

  exec {"bring_uplink":
    command => "/bin/sh $n1kuplink_location"
  }

  exec {"launch_vem":
    command => "/usr/sbin/service n1kv start",
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

  Package["libnl1"] -> Package["build-essential"] -> Package[$kernelheaders_pkg] -> Package["openvswitch-switch"] -> File["/etc/n1kv"] -> File[$imgfile] -> Package["nexus1000v"] -> File["/etc/n1kv/n1kv.conf"] -> File[$n1kuplink_location] -> Exec["bring_uplink"] -> Exec["launch_vem"]
}
