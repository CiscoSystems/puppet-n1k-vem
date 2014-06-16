# == Class: n1k-vem 
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
# virt vtep-int2 profile profint mode static address 192.168.2.91 netmask 255.255.255.0,
# virt vtep-int1 profile profint mode dhcp,
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
#       B)Instead VEM rpm can be downloaded locally and the file-path 
#         can be specified here.
#     n1kv_version ==>'latest'. Instead specific version can be specified. 
#       Not applicable if 'n1kv_source' is a file. (Option-B above)
#
class n1k-vem (
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

  if $::osfamily == 'Ubuntu' {
    $puppet_file_location = "/etc/puppet/files/"
  } elsif $::osfamily == 'Redhat' {
    $puppet_file_location = "/usr/share/openstack-foreman-installer/puppet/modules/n1k-vem/files"
  }

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

  include n1k-vem::deploy
}
