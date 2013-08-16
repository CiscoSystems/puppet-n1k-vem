class n1k-vem::deploy {

  package { "libnl1":
         ensure => installed
  }

  file { '/etc/n1kv':
         owner => 'root',
         group => 'root',
         mode  => '664',
         ensure => directory,
         require => Package['libnl1']
  }

  file { $imgfile:
         owner => 'root',
         group => 'root',
         mode => '666',
         source => "puppet:///files/$imagename",
         require => File['/etc/n1kv']
  }

  package {"nexus1000v":
        provider => dpkg,
        ensure => installed,
        source => $imgfile,
        require => File[$imgfile]
  }

  file {"/etc/n1kv/n1kv.conf":
        owner => 'root',
        group => 'root',
        mode => '666',
        source => "puppet:///files/${n1kconfname}_n1k.conf",
        require => Package['nexus1000v']
  }

  exec {"launch_vem":
       command => "/usr/sbin/service n1kv start",
       unless => "/sbin/vemcmd show card"
  }
  
  File['/etc/n1kv/n1kv.conf'] -> Exec['launch_vem']

}
