#
# == Define: redis_cluster::repos
#
# This class is used by init.pp to configure the repositories.
#
# === Authors
#
# Copyright (c) Asher256
# Contact: contact@asher256.com
#
# === Examples
#
#   include redis_cluster::repos
#

class redis_cluster::repos {
  # should be Debian + version 8 (jessie)
  if $::operatingsystem == 'Debian' {
    if versioncmp($::lsbdistrelease, '8.0') >= 0 && versioncmp($::lsbdistrelease, '9.0') < 0 {
      # install the dotdeb repositories for Debian >= Jessie
      apt::source { 'apt_source_dotdeb':
        location => 'http://packages.dotdeb.org',
        release  => 'jessie',
        repos    => 'all',
      }

      exec { 'apt_key_add_dotdeb':
        command => 'curl -L --silent "http://www.dotdeb.org/dotdeb.gpg" | apt-key add -',
        unless  => 'apt-key list | grep -q dotdeb',
        path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ];
      }

      Exec['apt_key_add_dotdeb'] -> Apt::Source['apt_source_dotdeb'] -> Class['::apt::update']
    }
  }
  else {
    warning('Your operating system it not supported by "redis_cluster". I encourage you to contribute! (currently, only Debian >= Jessie is supported)')
  }
}

# vim:ft=puppet:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8:foldmethod=marker
