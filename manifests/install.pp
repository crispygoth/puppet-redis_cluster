#
# == Define: redis_cluster::install
#
# This class is used by init.pp to install Redis and Redis Sentinel. I
# recommend you to read init.pp if you want more informations about this Puppet
# module.
#
# === Authors
#
# Copyright (c) Asher256
# Contact: asher256@gmail.com
#
# === Examples
#
#   include redis_cluster::install
#
class redis_cluster::install {
  File {
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
  }

  Class['::apt::update'] -> Package <| |>

  if ($::redis_cluster::manage_sysctls)
  {
    #
    # Sysctl configuration
    #
    file { '/etc/sysctl.d/70-redis.conf':
      ensure  => present,
      content => 'vm.overcommit_memory=1
  net.core.somaxconn=1024',
    }

    exec { 'sysctl --load=/etc/sysctl.d/70-redis.conf':
      subscribe   => File['/etc/sysctl.d/70-redis.conf'],
      refreshonly => true,
    }
  }
  else
  {
    file { '/etc/sysctl.d/70-redis.conf':
      ensure  => absent
    }
  }

  #
  # Package
  #
  package { ['redis-server', 'redis-tools']:
    ensure  => $redis_cluster::redis_version,
    require => File['/etc/sysctl.d/70-redis.conf'],
  }

  package { 'ruby-redis':
    ensure  => present,
    require => Package['redis-server'],
  }

  file { '/usr/local/bin/redis-trib.rb':
    content => template('redis_cluster/redis-trib.rb'),
    mode    => '0755',
  }

  #
  # Some directories
  #
  file { $redis_cluster::redis_instances_path:
    ensure  => directory,
    owner   => 'redis',
    group   => 'redis',
    mode    => '0755',
    require => Package['redis-server'],
  }

  file { '/var/log/redis':
    ensure  => directory,
    owner   => 'redis',
    group   => 'redis',
    mode    => '0755',
    require => Package['redis-server'],
  }

  file { '/var/run/redis':
    ensure  => directory,
    owner   => 'redis',
    group   => 'redis',
    mode    => '0644',
    require => Package['redis-server'],
  }

  #
  # This modified version of init.d Redis is inspired by memcache
  # init script.
  #
  # It will run multiple redis servers at the same time.
  file { '/etc/init.d/redis':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('redis_cluster/redis-init.sh.erb'),
    require => Package['redis-server'],
  }
}

# vim:ft=puppet:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8:foldmethod=marker
