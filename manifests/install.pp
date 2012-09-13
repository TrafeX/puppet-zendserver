class zendserver::install {

    include apt

    apt::repository { "zend-server":
        url       => "http://repos.zend.com/zend-server/deb",
        distro    => 'server',
        repository=> 'non-free',
        key       => true,
        key_url   => 'http://repos.zend.com/zend.key',
    }

$php_version = 5.3

    package { "zend-server" :
        name => "zend-server-php-${php_version}",
        ensure => present,
        require => [
            Apt::Repository["zend-server"],
            Exec["aptget_update"],
        ],
    }



    #
    # If Zend cannot get its paths right, we will!
    # Symlink /usr/local/zend/var/log to /var/log/zend/zendserver
    # Symlink /usr/local/zend/tmp to /tmp
    # Bind mount /usr/local/zend/bin on /usr/bin
    #

#    mount { '/usr/bin':
#        device  => '/usr/local/zend/bin/',
#        ensure  => mounted,
#        fstype  => 'none',
#        options => 'rw,bind,defaults',
#        atboot => true,
#        require => [
#            Package["zend-server"]
#        ]
#    }

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
    
}
