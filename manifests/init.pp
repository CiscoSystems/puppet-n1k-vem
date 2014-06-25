# == Class: n1kv-vem 
#
# Deploy N1KV VEM on compute and network nodes.
#
# === Parameters
# [*n1kv_vsm_ip*]
#   (required) N1KV VSM(Virtual Supervisor Module) VM's IP.
#
# [*n1kv_vsm_domainid*]
#   (required) N1KV VSM DomainID.
#
# [*host_mgmt_intf*]
#   (required) Management Interface of node where VEM will be installed.
#
# [*uplink_profile*]
#   (optional) Uplink Interfaces that will be managed by VEM. The uplink 
#      port-profile that configures these interfaces should also be specified.
#   (format)   
#     eth1:profile_uplink1,eth2:profile_uplink2
#   (default)  empty 
#
# [*vtep_config*]
#   (optional) Virtual tunnel interface configuration. 
#              Eg:VxLAN tunnel end-points. 
#   (format) Comma separated list of vtep interfaces 
#            their Profile and IP config.
# virt vtep1 profile profint mode static address 192.168.2.91 netmask 255.255.255.0,
# virt vtep2 profile profint mode dhcp
#   (default) empty
#
#  [*additional_params*]
#  (optional)
#  (default)
#     brname      ==> 'br-int'
#     node_type   ==> 'compute'
#     vtep_in_same_subnet => 'false',
#     n1kv_source ==> 'n1kv-vem' rpm package repository. One of below
#       A)yum repository that hosts 'n1kv-vem' rpm package.
#       B)Instead VEM rpm can be downloaded locally (puppet-server) and this file-path 
#         can be specified here.
#     n1kv_version ==>'latest'. Instead specific version can be specified. 
#       Not applicable if 'n1kv_source' is a file. (Option-B above)
#
class n1kv-vem (
    $n1kv_vsm_ip = "10.10.10.250",
    $n1kv_vsm_domain_id = 1000,
    $host_mgmt_intf = "eth1",
    $uplink_profile = "",
    $vtep_config = "",
    $additional_params = {brname => 'br-int', 
                          node_type => 'compute',
                          vtep_in_same_subnet => 'false',
                          n1kv_source  => '/tmp/n1kv-vem.rpm',
                          n1kv_version => 'latest',
                          },
    )
{
  $uvembrname = $additional_params[brname]
  $isMultipleVtepInSameSubnet = $additional_params[vteps_same_subnet] 
  $vemimage = $additional_params[n1kv_source]
  $node_type = $additional_params[node_type]
  $vem_pkgver = $additional_params[n1kv_version]

  $puppet_file_location = "/etc/puppet/files"

  if $vemimage != "" {
    if inline_template("<%= vemimage.include?('ftp') %>") == "true" {
      $vemimage_uri = "ftp"
    }elsif inline_template("<%= vemimage.include?('http') %>") == "true" {
      $vemimage_uri = "http"
    } else {
      notice ( "Image local" )
      $vemimage_uri = "local"
      $imagename = inline_template('<%= File.basename(vemimage) %>')
      $imgfile = "/etc/n1kv/$imagename"
      $xx = generate("/bin/cp", "$vemimage", "$puppet_file_location/$imagename")
    }
  }


  $n1kv_pkg = "nexus1000v"
  $puppet_file_uri = "puppet:///extra_files/$imagename"
  case $::osfamily {
    'Redhat': {
      $pkg_provider = "rpm"
      $libnl_pkg = "libnl"
      $ovs_pkg = "openvswitch"
      $cmd_service = "/sbin/service"
    }
    'Ubuntu': {
      $pkg_provider = "dpkg"
      $libnl_pkg = "libnl1"
      $ovs_pkg = "openvswitch-switch"
      $cmd_service = "/usr/sbin/service"
    }
    default: {
      fail( "${::osfamily} not yet supported by n1k-vem")
    }
  }

  package { 'libnl':
    name => $libnl_pkg,
    ensure => 'installed'
  }

  package { 'openvswitch':
    name => $ovs_pkg,
    ensure => 'installed'
  }

  file { '/etc/n1kv':
    owner => 'root',
    group => 'root',
    mode  => '664',
    ensure => directory
  }

  #specify template corresponding to 'n1kv.conf'

  file {'/etc/n1kv/n1kv.conf':
    owner => 'root',
    group => 'root',
    mode => '666',
    content => template('n1kv-vem/n1kv.conf.erb'),
    require => File['/etc/n1kv'],
    ensure => present
  }

  if $vemimage_uri == 'local' {
    file { $imgfile:
      owner => 'root',
      group => 'root',
      mode => '666',
      source => $puppet_file_uri,
      require => File['/etc/n1kv'],
    }
    package {'nexus1000v':
      provider => $pkg_provider,
      name => $n1kv_pkg,
      ensure => latest,
      source => $imgfile,
      require => File[$imgfile]
    }
  } else {
    yumrepo { 'cisco-foreman':
      baseurl => $vemimage,
      descr => 'Cisco Internal repo for Foreman',
      enabled => 1,
      gpgcheck => 1,
      gpgkey => "$vemimage/RPM-GPG-KEY"
      #proxy => '_none_',
    }
    package {'nexus1000v':
      name => $n1kv_pkg,
      ensure => $n1kv_pkgver,
    }
  }

  service { nexus1000v:
    ensure => running,
    subscribe => File['/etc/n1kv/n1kv.conf'],
    restart => "$cmd_service nexus1000v restart"
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

  Package['libnl'] -> Package['openvswitch'] -> File['/etc/n1kv/n1kv.conf'] -> Package['nexus1000v'] -> Service[nexus1000v]
}
