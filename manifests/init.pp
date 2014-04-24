class n1k-vem (
    $n1kv_vsm_ip = "10.10.10.250",
    $n1kv_vsm_domain_id = 1000,
    $host_mgmt_intf = "eth1",
    $uplink_profile,
    $vtep_config = 'no',
    $additional_params = {brname => 'br-int', 
                          node_type => 'compute',
                          vtep_in_same_subnet => 'false',
                          n1kv_source  => '/tmp/vijanata.rpm',
                          n1kv_version => 'latest',
                          },
    )
{
    $n1kconfname = "default"
    $uvembrname = $additional_params[brname]
    $isMultipleVtepInSameSubnet = $additional_params[vteps_same_subnet] 
    $vemimage = $additional_params[n1kv_source]
    $node_type = $additional_params[node_type]
    $n1kv_pkgver = $additional_params[n1kv_version]

    if $vemimage != "" {
      if inline_template("<%= vemimage.include?('ftp') %>") == "true" {
        notice ( "Image includes ftp" )
        $vemimage_avail = "ftp"
      }elsif inline_template("<%= vemimage.include?('http') %>") == "true" {
        notice ( "Image includes http" )
        $vemimage_avail = "http"
      } else {
        notice ( "Image local" )
        $vemimage_avail = "local"
        $imagename = inline_template('<%= File.basename(vemimage) %>')
        $imgfile = "/etc/n1kv/$imagename"
        notice("The value is: ${vemimage} ${imagename} ${imgfile}")
      }
    }

    $n1kuplinkintfile = "${n1kconfname}_n1k.conf_uplink"
    $n1kuplink_location = "/etc/n1kv/$n1kuplinkintfile"

    if $::osfamily == 'Ubuntu' {
      $puppet_file_location = "/etc/puppet/files/"
      if $vemimage_avail == 'local' {
        $xx = generate("/usr/bin/sudo", "/bin/cp", "$vemimage", "$puppet_file_location/$imagename")
      }
    } elsif $::osfamily == 'Redhat' {
      $puppet_file_location = "/usr/share/openstack-foreman-installer/puppet/modules/n1k-vem/files"
      if $vemimage_avail == 'local' {
        $xx = generate("/bin/cp", "$vemimage", "$puppet_file_location/$imagename")
      }
    }

    include n1k-vem::generaten1kconf
    include n1k-vem::deploy

    Class['n1k-vem::generaten1kconf'] -> Class['n1k-vem::deploy']
}
