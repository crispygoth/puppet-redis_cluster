#
# == Define: redis_cluster::load_instances
#
# Load the redis instances, when the installation is ready. I recommend you to
# read init.pp if you want more informations about this Puppet module.
#
# === Authors
#
# Asher256 <contact@asher256.com>
# Copyright (c) Asher256
#
# === Examples
#
#   include redis_cluster::load_instances
#
class redis_cluster::load_instances {
  # Hiera instances
  $instances = hiera_hash('redis_cluster::instances', {})
  create_resources('redis_cluster::instance', $instances)
}

# vim:ft=puppet:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8:foldmethod=marker
