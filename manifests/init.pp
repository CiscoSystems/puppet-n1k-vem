class vem::compute(
    $vemimage,
    $vsmip,
    $domainid,
    $ctrlmac,
    $hostmgmtint,
    $uplinkint,
    $uvembrname = "n1kvdvs",
    $conftemplate = "default",
    $n1kconftemplate = "vem/n1kv.conf.erb" )
{

  $b = inline_template('<%= File.basename(vemimage) %>')
  $imgfile = "/etc/n1kv/$b"
  $xx = generate("/usr/bin/sudo", "/bin/cp", "$vemimage", "/etc/puppet/files/$b")

  include vem::generaten1kconf
  include vem::deploy
  
  Class['vem::generaten1kconf'] -> Class['vem::deploy']

}
