
class zendserver::package (
  $version = 'UNSET'
  ) {
  
  include apt

  case $version {
    'UNSET',
      '6.0':     { $repo = "http://repos.zend.com/zend-server/6.0/beta/deb" }
    '5.6':         { $repo = "http://repos.zend.com/zend-server/deb" }
    default:       { raise Puppet::ParseError, "Unknown Zend Server version specified." }
  }

  apt::repository { "zend-server":
    url       => $repo,
    distro    => 'server',
    repository=> 'non-free',
    key       => true,
    key_url   => 'http://repos.zend.com/zend.key',
  }
}
