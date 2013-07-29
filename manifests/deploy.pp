class vem::deploy {

  file {'/etc/default/grub':
         owner => 'root',
         group => 'root',
         mode => '666',
         source => "puppet:///modules/vem/grub",
  }

  exec {"update-grub":
       command => "/usr/sbin/update-grub",
       require => File['/etc/default/grub']
  }

  package { 'linux-image-3.2.0-29-generic':
          ensure => 'installed',
          notify => Exec["/sbin/reboot"],
          require => Exec['update-grub']
  }

  exec { "/sbin/reboot":
          refreshonly => "true",
          require => Package['linux-image-3.2.0-29-generic']
  }

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
         source => "puppet:///files/$b",
         require => File['/etc/n1kv']
  }

  package {"nexus100v":
        provider => dpkg,
        ensure => installed,
        source => $imgfile,
        require => File[$imgfile]
  }

  file {"/etc/n1kv/n1kv.conf":
        owner => 'root',
        group => 'root',
        mode => '666',
        content => template($n1kconftemplate)
  }

  exec {"launch_vem":
       command => "/usr/sbin/service n1kv start",
       unless => "/sbin/vemcmd show card"
  }
  
  File['/etc/n1kv/n1kv.conf'] -> Exec['launch_vem']

}
