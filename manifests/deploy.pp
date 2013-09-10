class n1k-vem::deploy {

  package { "libnl1":
    name => "libnl1",
    ensure => "installed"
  }

  if $enable_ovs_agent {
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

  exec {"launch_vem":
    command => "/usr/sbin/service n1kv start",
    unless => "/sbin/vemcmd show card"
  }

  File["/etc/n1kv"] -> File[$imgfile] -> Package["nexus1000v"] -> File["/etc/n1kv/n1kv.conf"] -> Exec["launch_vem"]

}
