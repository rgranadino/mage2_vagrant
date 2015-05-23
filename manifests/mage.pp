stage { 'first':
  before => Stage['main']
}

class dotdeb {
  file { '/etc/apt/sources.list':
    source => '/vagrant/files/apt.sources.list',
    owner  => 'root',
    group  => 'root'
  }
  exec { 'apt-get update':
    command   => '/usr/bin/apt-get update',
    subscribe => File['/etc/apt/sources.list'],
  }
  exec { "Import dotdeb to apt keystore":
    path        => '/bin:/usr/bin',
    environment => 'HOME=/root',
    command     => "wget -O - dotdeb.org/dotdeb.gpg | apt-key add -",
    user        => 'root',
    group       => 'root',
    unless      => "apt-key list | grep dotdeb",
  }
}

class { 'dotdeb':
  stage => 'first'
}

class { 'composer':
  command_name => 'composer',
  target_dir   => '/usr/local/bin',
  auto_update  => true
}

############
# packages #
############

package { [
  'vim',
  'apache2',
  'apache2-suexec',
  'libapache2-mod-fastcgi',
  'rsync',
  'htop',
  'python',
  'graphviz',
  'mysqltuner',
  'nfs-common',
]:
  ensure  => 'latest',
  require => Exec['apt-get update']
}

package { [
  'mysql-common',
  'mysql-server'
]:
  ensure  => 'latest',
  require => Package['apache2'],
}

package { [
  'php5-cli',
  'php5-common',
  'php5-curl',
  'php5-gd',
  'php5-intl',
  'php5-mcrypt',
  'php5-fpm',
  'php5-memcached',
  'php5-mysql',
  'php5-xsl',
  'php5-xdebug',
  'phpunit',
  'php-codesniffer',
]:
  ensure  => 'latest',
  require => Package['mysql-common']
}

package { [
  'libapache2-mod-fcgid',
  'libapache2-mod-php5filter'
]:
  ensure => 'absent'
}

###############
# executables #
###############

exec { 'set-mysql-password':
  unless  => '/usr/bin/mysqladmin -uroot -pmage2 status',
  command => '/usr/bin/mysqladmin -uroot password mage2',
  require => Service['mysql'],
  notify  => Exec['remove-local-xml'],
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

exec { 'remove-local-xml':
  command     => '/bin/rm /vagrant/data/magento2/app/etc/local.xml',
  require     => Exec['create-mage-db'],
  onlyif      => "/usr/bin/test -f /vagrant/data/magento2/app/etc/local.xml",
  refreshonly => true,
}

############
# services #
############

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
  ensure     => running,
  hasstatus  => true,
  hasrestart => true,
  require    => Package['php5-fpm'],
}

file { '/usr/local/bin/dot':
  ensure => 'link',
  target => '/usr/bin/dot'
}

#######################
# configuration files #
#######################

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

file { '/etc/apache2/sites-enabled/001-stats':
  source  => '/vagrant/files/stats.conf',
  require => Package['php5-fpm'],
  notify  => Service['apache2']
}

file { '/var/www/info.php':
  source  => '/vagrant/files/info.php',
  require => Package['apache2']
}

file { '/var/www/opcache.php':
  source  => '/vagrant/files/opcache.php',
  require => Package['apache2']
}

##############
# xdebug ini #
##############

file { '/etc/php5/fpm/conf.d/21-xdebug.ini':
  source  => '/vagrant/files/xdebug.ini',
  require => Package['php5-fpm', 'php5-xdebug'],
  notify  => Service['php5-fpm']
}

file { '/etc/php5/cli/conf.d/21-xdebug.ini':
  source  => '/vagrant/files/xdebug.ini',
  require => Package['php5-cli', 'php5-xdebug']
}

##################
# helper scripts #
##################

file { '/home/vagrant/bin':
  ensure => 'directory',
  owner  => 'vagrant',
  group  => 'vagrant',
  mode   => 0775
}

file { '/home/vagrant/bin/reinstall':
  owner    => 'vagrant',
  group    => 'vagrant',
  source   => '/vagrant/files/reinstall.sh',
  mode     => '0755',
  require  => File['/home/vagrant/bin']
}

file { '/home/vagrant/.bash_aliases':
  owner    => 'vagrant',
  group    => 'vagrant',
  source   => '/vagrant/files/bash_aliases',
  mode     => '0755',
  require  => File['/home/vagrant/bin']
}

#########
# crons #
#########

cron { 'puppetapply':
  command => 'puppet apply /vagrant/manifests/mage.pp',
  user    => 'root',
  minute  => '*/15'
}

###################
# disable modules #
###################

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
apache2mod { 'status': ensure => present }

#############################################
# wrapper for enable/disable apache modules #
#############################################

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
