class n1k-vem (
    $vemimage,
    $vsmip,
    $domainid,
    $ctrlmac,
    $hostmgmtint,
    $uplinkint,
    $profile,
    $uvembrname = "br-int",
    $vtepconfig,
    $n1kconfname = "default" )
{

  $imagename = inline_template('<%= File.basename(vemimage) %>')
  $imgfile = "/etc/n1kv/$imagename"
  $xx = generate("/usr/bin/sudo", "/bin/cp", "$vemimage", "/etc/puppet/files/$imagename")

  include n1k-vem::generaten1kconf
  include n1k-vem::deploy
  
  Class['n1k-vem::generaten1kconf'] -> Class['n1k-vem::deploy']

}
