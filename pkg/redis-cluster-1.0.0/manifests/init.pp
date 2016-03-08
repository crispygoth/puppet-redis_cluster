#
# == Define: redis_cluster
#
# 'redis_cluster::*' classes use Augeas to configure:
#   - Redis cluster (Redis >= 3.0)
#   - Redis (with Augeas)
#   - Multiple Redis Instances
#     (with a custom /etc/init.d/ script)
#
# Once Redis is installed and configured by this module, you will need to
# initialize the cluster yourself with redis-trib (you have to do it one time).
# I recommend you this redis-trib / Redis cluster howto:
# http://redis.io/topics/cluster-tutorial
#
# Requirements:
# - Puppet modules: stdlib
# - Operating system: Debian Jessie (and more)
#
# This class follows the recommendations of the "Puppet Labs Style Guide":
# http://docs.puppetlabs.com/guides/style_guide.html . If you want to
# contribute, please check your code with puppet-lint.
#
# === Authors
#
# Copyright (c) Asher256
# Contact: contact@asher256.com
#
# === Examples
#
# class {'redis_cluster':
#   redis_version   => 'present',
# }
#
# redis_cluster::instance{'redis1':
#   ip   => '127.0.0.1',
#   port => '7000',
# }
#
# redis_cluster::instance{'redis2':
#   ip   => '127.0.0.1',
#   port => '7001',
# }
#
# === Parameters
#
# [*redis_version*]           you can specify: 'present' OR the redis version (e.g. "3.0.0")
# [*cluster_node_timeout*]    the cluster timeout (read the Redis doc)
# [*redis_instances_path*]    the directory where the different instances will be saved
# [*systemd*]                 use systemd
#
class redis_cluster(
  $redis_version        = 'present',
  $cluster_node_timeout = 15000,
  $redis_instances_path = '/opt/redis',
  $systemd              = true,
)
{
  validate_string($redis_version)
  validate_integer($cluster_node_timeout)
  validate_bool($systemd)

  include redis_cluster::repos
  include redis_cluster::install
  include redis_cluster::load_instances

  service { 'redis-server':
    ensure => stopped,
    enable => false,
  }

  Class['::redis_cluster::repos']
  -> Class['::redis_cluster::install']
  -> Service['redis-server']
  -> Class['::redis_cluster::load_instances']
}

# vim:ft=puppet:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8:foldmethod=marker
