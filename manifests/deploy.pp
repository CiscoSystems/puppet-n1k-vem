class n1k-vem::deploy {

  $vempackages = ["libnl1" ,"openvswitch-switch"]
  package { "vempackages":
    name => $vempackages,
    ensure => "installed"
  }

  service { 'n1kv':
    restart => '/usr/sbin/service n1kv restart'
  }

  package { "libnl1":
    ensure => installed
  }

  file { '/etc/n1kv':
    owner => 'root',
    group => 'root',
    mode  => '664',
    ensure => directory,
    require => Package[$vempackages],
  }

  file { $imgfile:
    owner => 'root',
    group => 'root',
    mode => '666',
    source => "puppet:///files/$imagename",
    require => File['/etc/n1kv'],
  }

  package {"nexus1000v":
    provider => dpkg,
    ensure => latest,
    source => $imgfile,
    require => File[$imgfile]
  }

  file {"/etc/n1kv/n1kv.conf":
    owner => 'root',
    group => 'root',
    mode => '666',
    source => "puppet:///files/${n1kconfname}_n1k.conf",
    require => Package['nexus1000v'],
    notify => Service['n1kv']
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

  Package[libnl1] -> File['/etc/n1kv'] -> File[$imgfile] -> Package["nexus1000v"] -> File['/etc/n1kv/n1kv.conf'] -> File[$n1kuplink_location] -> Exec["bring_uplink"] -> Exec['launch_vem']

}
