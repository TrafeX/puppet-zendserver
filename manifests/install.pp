class zendserver::install {

    include apt

    apt::repository { "zend-server":
        url => 'http://repos.zend.com/zend-server/deb',
        distro => 'server',
        repository => 'non-free',
        key => true,
        key_url => 'http://repos.zend.com/zend.key'
    }

    # This block seems to have no effect, and still to require this to be run twice?
    exec { "apt-get update":
        command => "/usr/bin/apt-get update",
    }

    package { "zend-server-php-${params::php_version}":
        ensure => present,
        require => [
            Apt::Repository["zend-server"],
            Exec["apt-get update"],
        ],
    }



    #
    # If Zend cannot get its paths right, we will!
    # Symlink /usr/local/zend/var/log to /var/log/zend/zendserver
    # Symlink /usr/local/zend/tmp to /tmp
    # Bind mount /usr/local/zend/bin on /usr/bin
    #

    file { "zend-log-path":
        path   => "/var/log/zend",
        owner  => zend,
        group  => zend,
        ensure => directory,
        mode   => 775,
        require => [
            Package["zend-server-php-${params::php_version}"]
        ]
    }

    file { "zendserver-log-path":
        path   => "/var/log/zend/zendserver",
        owner  => www-data,
        group  => zend,
        ensure => directory,
        mode   => 775,
        force => true,
        require => [
            File["zend-log-path"]
        ]
    }

    exec { "mv /usr/local/zend/var/log/* /var/log/zend/zendserver/":
        onlyif => "/bin/sh -c '[ ! -h /usr/local/zend/var/log ]'",
        require => [
            File["zendserver-log-path"],
        ]
    }

    file { "zendserver-log-symlink":
        path   => "/usr/local/zend/var/log",
        ensure => "link",
        target => "/var/log/zend/zendserver",
        force => true,
        require => [
            File["zendserver-log-path"],
            Exec["mv /usr/local/zend/var/log/* /var/log/zend/zendserver/"]
        ],
    }

    exec { "mv /usr/local/zend/tmp/* /tmp/":
        onlyif => "/bin/sh -c '[ ! -h /usr/local/zend/tmp ]'",
        require => [
            Package["zend-server-php-${params::php_version}"]
        ]
    }

    file { "zendserver-tmp-symlink":
        path   => "/usr/local/zend/tmp",
        ensure => "link",
        target => "/tmp",
        force => true,
        require => [
            Package["zend-server-php-${params::php_version}"],
            Exec['mv /usr/local/zend/tmp/* /tmp/'],
        ]
    }

    mount { '/usr/local/bin':
        device  => '/usr/local/zend/bin/',
        ensure  => mounted,
        fstype  => 'none',
        options => 'rw,bind,defaults',
        atboot => true,
        require => [
            Package["zend-server-php-${params::php_version}"]
        ]
    }
}
