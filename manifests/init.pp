class n1k-vem (
    $vemimage,
    $vsmip,
    $domainid,
    $hostmgmtint,
    $uplinkint,
    $uvembrname = "br-int",
    $vtepconfig = "no",
    $isMultipleVtepInSameSubnet = "false", 
    $n1kconfname = "default",
    $node_type = "compute", )
{

  $imagename = inline_template('<%= File.basename(vemimage) %>')
  $imgfile = "/etc/n1kv/$imagename"
  $xx = generate("/usr/bin/sudo", "/bin/cp", "$vemimage", "/etc/puppet/files/$imagename")

  $n1kuplinkintfile = "${n1kconfname}_n1k.conf_uplink"
  $n1kuplink_location = "/etc/n1kv/$n1kuplinkintfile"

  include n1k-vem::generaten1kconf
  include n1k-vem::deploy
  
  Class['n1k-vem::generaten1kconf'] -> Class['n1k-vem::deploy']

}
