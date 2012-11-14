class zendserver (
  $version             = 6.0,
  $php_version         = 5.4,
  $firewall            = params_lookup( 'firewall' , 'global' ),
  $firewall_tool       = params_lookup( 'firewall_tool' , 'global' ),
  $firewall_src        = params_lookup( 'firewall_src' , 'global' ),
  $firewall_dst        = params_lookup( 'firewall_dst' , 'global' ),
  ) {
   
  $bool_firewall=any2bool($firewall)
  if $zendserver::bool_absent == true or $zendserver::bool_disable == true {
    $manage_firewall = false
  } else {
    $manage_firewall = true
  }
    

  class { 'zendserver::package' :
    version => $version,
  }

  package { "zend-server" :
    name => "zend-server-php-${php_version}",
    ensure => present,
    require => [
      Apt::Repository["zend-server"],
#      Exec["aptget_update"],
    ],
  }
  
  #
  # If Zend cannot get its paths right, we will!
  # Symlink /usr/local/zend/var/log to /var/log/zend/zendserver
  # Symlink /usr/local/zend/tmp to /tmp
  # Add /usr/local/zend/bin to the PATH environment variable
  #

  file { "zend-path" :
    path   => "/etc/profile.d/zend.sh",
    source => "puppet:///modules/zendserver/zend.sh",
    owner  => "root",
    group  => "root",
    mode   => 0644,
  }

  file { "/var/log/zend/zendserver":
    owner  => www-data,
    group  => zend,
    ensure => directory,
    mode   => 775,
    force => true,
    require => [
      File["/var/log/zend"]
    ]
  }

  file { "/usr/local/zend/var/log":
    ensure => "link",
    target => "/var/log/zend/zendserver",
    force => true,
    require => [
      File["/var/log/zend/zendserver"],
      Exec["mv /usr/local/zend/var/log/* /var/log/zend/zendserver/"]
    ],
  }

  file { "/usr/local/zend/tmp":
    ensure => "link",
    target => "/tmp",
    force => true,
    require => [
      Package["zend-server"],
      Exec['mv /usr/local/zend/tmp/* /tmp/'],
    ]
  }
  
  exec { "mv /usr/local/zend/tmp/* /tmp/":
    onlyif => "/bin/sh -c '[ ! -h /usr/local/zend/tmp ]'",
    require => [
      Package["zend-server"]
    ]
  }
  
  exec { "mv /usr/local/zend/var/log/* /var/log/zend/zendserver/":
    onlyif => "/bin/sh -c '[ ! -h /usr/local/zend/var/log ]'",
    require => [
      File["/var/log/zend/zendserver"],
    ]
  }

  file { "/var/log/zend":
    owner  => zend,
    group  => zend,
    ensure => directory,
    mode   => 775,
    require => [
      Package["zend-server"]
    ]
  }

  #
  # Firewall
  #
  if $apache::bool_firewall == true {
    firewall { "zendserver_tcp_10081":
      source        => $zendserver::firewall_src,
      destination   => $zendserver::firewall_dst,
      protocol      => 'tcp',
      port          => 10081,
      action        => 'allow',
      direction     => 'input',
      tool          => $zendserver::firewall_tool,
      enable        => $zendserver::manage_firewall,
    }
    
    firewall { "zendserver_tcp_10082":
      source        => $zendserver::firewall_src,
      destination   => $zendserver::firewall_dst,
      protocol      => 'tcp',
      port          => 10082,
      action        => 'allow',
      direction     => 'input',
      tool          => $zendserver::firewall_tool,
      enable        => $zendserver::manage_firewall,
    }
  }


  # TODO Should this be here like that?  
  include zendserver::service
  
}
