class n1k-vem (
    $vsmip = "10.0.0.29",
    $domainid = 1111,
    $hostmgmtint = "eth1",
    $uplinkint,
    $extparams = {brname => 'br-int', 
                  node_type => 'compute',
                  vtep_config => 'no',
                  vteps_same_subnet => 'false',
                  vemimage  => '/tmp/vijanata.rpm'
                  },
    )
{
    $n1kconfname = "default"
    $uvembrname = $extparams[brname]
    $vtepconfig = $extparams[vtep_config]
    $isMultipleVtepInSameSubnet = $extparams[vteps_same_subnet] 
    $vemimage = $extparams[vemimage]
    $node_type = $extparams[node_type]

#  notice ( $extparams[node_type] )
#  notify {"888 $node1_type":}
#  $vemimage1 = "http://10.193.199.136/pub/hostedrepo"
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
      $xx = generate("/usr/bin/sudo", "/bin/cp", "$vemimage", "$puppet_file_location/$imagename")
    } elsif $::osfamily == 'Redhat' {
      $puppet_file_location = "/usr/share/openstack-foreman-installer/puppet/modules/n1k-vem/files"
      if $vemimage_avail == 'local' {
      #  $xx = generate("/bin/cp", "$vemimage", "$puppet_file_location/$imagename")
      }
    }

    include n1k-vem::generaten1kconf
    include n1k-vem::deploy

    Class['n1k-vem::generaten1kconf'] -> Class['n1k-vem::deploy']
}
