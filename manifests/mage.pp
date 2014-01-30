#packages
package {[
    'vim',
    'apache2',
    'apache2-suexec',
    'libapache2-mod-fastcgi',
    ]:
    ensure  => 'latest',
    require => Exec['apt-get update']
}
package {[
    'mysql-common',
    'mysql-server'
    ]:
    ensure  => 'latest',
    require => Package['apache2'],
}

package {[
    'php5-cli',
    'php5-common',
    'php5-curl',
    'php5-gd',
    'php5-intl',
    'php5-mcrypt',
    'php5-fpm',
    'php5-memcached',
    'php5-mysql',
    'php5-xdebug',
    'phpunit',
    ]:
    ensure  => 'latest',
    require => Package['mysql-common']
}
package {[
    'libapache2-mod-fcgid',
    'libapache2-mod-php5filter'
    ]:
    ensure => 'absent'
}
#executables
exec { 'apt-get update':
    command  => '/usr/bin/apt-get update',
    require  => Exec['add-non-free']
}
exec {'add-non-free':
    command => '/bin/sed -e \'s/deb http.* wheezy main$/& non-free/\' -i /etc/apt/sources.list'
}
exec { 'set-mysql-password':
    unless  => '/usr/bin/mysqladmin -uroot -pmage2 status',
    command => '/usr/bin/mysqladmin -uroot password mage2',
    require => Service['mysql'],
}
exec { 'create-mage-db':
    unless  => '/usr/bin/mysql -uroot -pmage2 -e "use mage2"',
    command => '/usr/bin/mysql -uroot -pmage2 -e "create database mage2; grant all on mage2.* to root@localhost identified by \'mage2\';"',
    require => Exec['set-mysql-password'],
}
exec { 'reload-apache2':
    command     => '/etc/init.d/apache2 reload',
    refreshonly => true
}
exec { 'reload-php5-fpm':
    command     => '/etc/init.d/php5-fpm reload',
    refreshonly => true
}
#services
service { 'apache2':
    ensure     => running,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['apache2'],
}
service { 'mysql':
    ensure  => running,
    enable  => true,
    require => Package['mysql-server'],
    notify  => Exec['create-mage-db']
}
service { 'php5-fpm':
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    require    => Package['php5-fpm'],
}

#files/configuration
file { '/etc/apache2/sites-enabled/000-default':
    ensure  => 'absent',
    require => Package['apache2'],
    notify  => Exec['reload-apache2']
}
file { '/etc/apache2/mods-available/fastcgi.conf':
    source  => '/vagrant/files/fastcgi.conf',
    require => Package['apache2'],
    notify  => Exec['reload-php5-fpm']
}
file { '/etc/php5/fpm/pool.d/www.conf':
    source  => '/vagrant/files/www.conf',
    require => Package['php5-fpm'],
    notify  => Exec['reload-php5-fpm']
}
file { '/etc/apache2/sites-enabled/000-mage2':
    source  => '/vagrant/files/site.conf',
    require => Package['php5-fpm'],
    notify  => Service['apache2']
}
#xdebug ini
file { '/etc/php5/conf.d/21-xdebug.ini':
    source  => '/vagrant/files/xdebug.ini',
    require => Package['php5-xdebug'],
    notify  => Service['php5-fpm']
}

#crons
cron { 'puppetapply':
      command => 'puppet apply /vagrant/manifests/mage.pp',
      user    => 'root',
      minute  => '*/15'
}

#disable any modules we don't need
apache2mod { 'deflate': ensure => present }
apache2mod { 'suexec': ensure => present }
apache2mod { 'rewrite': ensure => present }
apache2mod { 'include': ensure => present }
apache2mod { 'alias': ensure => present }
apache2mod { 'actions': ensure => present }
apache2mod { 'auth_basic': ensure => absent }
apache2mod { 'authn_file': ensure => absent }
apache2mod { 'authz_groupfile': ensure => absent }
apache2mod { 'authz_user': ensure => absent }
apache2mod { 'cgid': ensure => absent }
apache2mod { 'status': ensure => absent }

#wrapper to enable/disable apache modules properly
define apache2mod ( $ensure = 'present', $require_package = 'apache2' ) {
    case $ensure {
        'present' : {
            exec { "/usr/sbin/a2enmod ${name}":
            unless  => "/bin/sh -c '[ -L /etc/apache2/mods-enabled/${name}.load ] \\
               && [ /etc/apache2/mods-enabled/${name}.load -ef /etc/apache2/mods-available/${name}.load ]'",
            notify  => Exec['reload-apache2'],
            require => Package[$require_package],
            }
        }
        'absent': {
            exec { "/usr/sbin/a2dismod ${name}":
            onlyif  => "/bin/sh -c '[ -L /etc/apache2/mods-enabled/${name}.load ] \\
              && [ /etc/apache2/mods-enabled/${name}.load -ef /etc/apache2/mods-available/${name}.load ]'",
            notify  => Exec['reload-apache2'],
            require => Package['apache2'],
            }
        }
    }
}
