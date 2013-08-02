class n1k-vem (
    $vemimage,
    $vsmip,
    $domainid,
    $ctrlmac,
    $hostmgmtint,
    $uplinkint,
    $profile,
    $uvembrname = "n1kvdvs",
    $vtepconfig,
    $n1kconfname = "default" )
{

  $b = inline_template('<%= File.basename(vemimage) %>')
  $imgfile = "/etc/n1kv/$b"
  $xx = generate("/usr/bin/sudo", "/bin/cp", "$vemimage", "/etc/puppet/files/$b")

  include n1k-vem::generaten1kconf
  include n1k-vem::deploy
  
  Class['n1k-vem::generaten1kconf'] -> Class['n1k-vem::deploy']

}
