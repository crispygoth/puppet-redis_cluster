#
# == Define: redis_cluster::instance
#
# This class configures Redis. I recommend you to read init.pp if you want more
# informations about this Puppet module.
#
# === Authors
#
# Copyright (c) Asher256
# Contact: asher256@gmail.com
#

#
# define redis_cluster::redis_service
#
# Example:
# ========
# redis_cluster::redis_service {'master':
#   redis_port => 7000,
# }
#
define redis_cluster::instance::service(
  $redis_port,
) {
  if $redis_cluster::systemd {
    $redis_config = "/etc/redis/redis-server-${name}.conf"

    file { "/lib/systemd/system/redis-server-${name}.service":
      content => template('redis_cluster/redis-systemd.service.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }

    service { "redis-server-${name}":
      ensure   => running,
      enable   => true,
      provider => systemd,
      require  => File["/lib/systemd/system/redis-server-${name}.service"],
    }
  }
}

#
# An instance of Redis
#
define redis_cluster::instance(
  $ip,
  $port,
  $save_enabled                  = true,
  $tcp_backlog                   = 511,
  $timeout                       = 0,
  $tcp_keepalive                 = 0,
  $log_level                     = 'notice',
  $databases                     = 16,    # TODO: 1 database by default?
  $stop_writes_on_bgsave_error   = true,
  $rdbcompression                = true,
  $rdbchecksum                   = true,
  $unixsocket                    = undef,
  $unixsocketperm                = undef,
  $masterauth                    = undef,
  $slave_serve_stale_data        = true,
  $slave_read_only               = true,
  $repl_disable_tcp_nodelay      = false,
  $repl_backlog_size             = '1mb',
  $repl_backlog_ttl              = 3600,
  $repl_ping_slave_period        = 10,
  $repl_timeout                  = 10,
  $slave_priority                = 100,
  $min_slaves_to_write           = 0,
  $min_slaves_max_lag            = 10,
  $requirepass                   = undef,
  $maxmemory                     = undef,
  $maxclients                    = 10000,
  $maxmemory_policy              = 'volatile-lru',
  $appendonly                    = true,
  $appendfsync                   = 'everysec',
  $no_appendfsync_on_rewrite     = false,
  $auto_aof_rewrite_percentage   = 100,
  $auto_aof_rewrite_min_size     = '64mb',
  $lua_time_limit                = 5000,
  $slowlog_log_slower_than       = 128,
  $slowlog_max_len               = 10000,
  $latency_monitor_threshold     = 0,
  $hash_max_ziplist_entries      = 512,
  $hash_max_ziplist_value        = 64,
  $list_max_ziplist_entries      = 512,
  $list_max_ziplist_value        = 64,
  $set_max_intset_entries        = 512,
  $zset_max_ziplist_entries      = 128,
  $zset_max_ziplist_value        = 64,
  $hll_sparse_max_bytes          = 3000,
  $activerehashing               = true,
  $hz                            = 10,
  $aof_rewrite_incremental_fsync = true,
) {
  #
  # Validating
  #
  validate_string($ip)
  validate_integer($port)
  validate_integer($tcp_backlog)
  validate_integer($timeout)
  validate_integer($tcp_keepalive)
  validate_re($log_level, '^debug$|^verbose$|^notice$|^warning$')
  validate_integer($databases)
  validate_bool($stop_writes_on_bgsave_error)
  validate_bool($rdbcompression)
  validate_bool($rdbchecksum)
  validate_string($unixsocket)
  validate_string($unixsocketperm)
  validate_string($masterauth)
  validate_bool($slave_serve_stale_data)
  validate_bool($slave_read_only)
  validate_bool($repl_disable_tcp_nodelay)
  validate_string($repl_backlog_size)
  validate_integer($repl_backlog_ttl)
  validate_integer($repl_ping_slave_period)
  validate_integer($repl_timeout)
  validate_integer($slave_priority)
  validate_integer($min_slaves_to_write)
  validate_integer($min_slaves_max_lag)
  validate_string($requirepass)
  validate_string($maxmemory)
  validate_integer($maxclients)
  validate_re($maxmemory_policy, '^volatile-lru$|^allkeys-lru$|^volatile-random$|^allkeys-random$|^volatile-ttl$|^noeviction$')
  validate_bool($appendonly)
  validate_re($appendfsync, '^everysec$|^always$|^no$')
  validate_bool($no_appendfsync_on_rewrite)
  validate_integer($auto_aof_rewrite_percentage)
  validate_string($auto_aof_rewrite_min_size)
  validate_integer($lua_time_limit)
  validate_integer($slowlog_log_slower_than)
  validate_integer($slowlog_max_len)
  validate_integer($latency_monitor_threshold)
  validate_integer($hash_max_ziplist_entries)
  validate_integer($hash_max_ziplist_value)
  validate_integer($list_max_ziplist_entries)
  validate_integer($list_max_ziplist_value)
  validate_integer($set_max_intset_entries)
  validate_integer($zset_max_ziplist_entries)
  validate_integer($zset_max_ziplist_value)
  validate_integer($hll_sparse_max_bytes)
  validate_bool($activerehashing)
  validate_integer($hz)
  validate_bool($aof_rewrite_incremental_fsync)

  Exec {
    user    => 'root',
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    require => Class['::redis_cluster'],
  }

  File {
    require => Class['::redis_cluster'],
  }

  #
  # global variables
  #
  $redis_name = $name
  $redis_config = "/etc/redis/redis-server-${redis_name}.conf"

  #
  # some directories / files
  #
  file { "${redis_cluster::redis_instances_path}/${redis_name}":
    ensure  => directory,
    owner   => 'redis',
    group   => 'redis',
    mode    => '0755',
    require => [File[$redis_cluster::redis_instances_path],
                Package['redis-server']],
  }

  file { "/var/log/redis/redis-server-${redis_name}.log":
    ensure  => present,
    owner   => 'redis',
    group   => 'redis',
    mode    => '0644',
    require => [File['/var/log/redis'],
                Package['redis-server']],
  }

  $cluster_enabled = true    # always enabled

  if $cluster_enabled == true {
    $cluster_enabled_value = 'yes'
  } else {
    $cluster_enabled_value = 'no'
  }

  if $repl_disable_tcp_nodelay == true {
    $repl_disable_tcp_nodelay_value = 'yes'
  } else {
    $repl_disable_tcp_nodelay_value = 'no'
  }

  if $activerehashing == true {
    $activerehashing_value = 'yes'
  } else {
    $activerehashing_value = 'no'
  }

  if $rdbchecksum == true {
    $rdbchecksum_value = 'yes'
  } else {
    $rdbchecksum_value = 'no'
  }

  if $stop_writes_on_bgsave_error == true {
    $stop_writes_on_bgsave_error_value = 'yes'
  } else {
    $stop_writes_on_bgsave_error_value = 'no'
  }

  if $rdbcompression == true {
    $rdbcompression_value = 'yes'
  } else {
    $rdbcompression_value = 'no'
  }

  if $no_appendfsync_on_rewrite == true {
    $no_appendfsync_on_rewrite_value = 'yes'
  } else {
    $no_appendfsync_on_rewrite_value = 'no'
  }

  if $aof_rewrite_incremental_fsync == true {
    $aof_rewrite_incremental_fsync_value = 'yes'
  } else {
    $aof_rewrite_incremental_fsync_value = 'no'
  }

  if $appendonly == true {
    $appendonly_value = 'yes'
  }
  else {
    $appendonly_value = 'no'
  }

  if $slave_read_only == true {
    $slave_read_only_value = 'yes'
  }
  else {
    $slave_read_only_value = 'no'
  }

  if $slave_serve_stale_data == true {
    $slave_serve_stale_data_value = 'yes'
  }
  else {
    $slave_serve_stale_data_value = 'no'
  }

  if $maxmemory == undef {
    $maxmemory_set = 'rm maxmemory' # remove
  }
  else {
    $maxmemory_set = "set maxmemory '${maxmemory}'"
  }

  if $requirepass == undef {
    $requirepass_set = 'rm requirepass'
  }
  else {
    $requirepass_set = "set requirepass '${requirepass}'"
  }

  if $masterauth == undef {
    $masterauth_set = 'rm masterauth'
  }
  else {
    $masterauth_set = "set masterauth '${masterauth}'"
  }

  if $unixsocket == undef {
    $unixsocket_set = 'rm unixsocket'
  }
  else {
    $unixsocket_set = "set unixsocket '${unixsocket}'"
  }

  if $unixsocketperm == undef {
    $unixsocketperm_set = 'rm unixsocketperm'
  }
  else {
    $unixsocketperm_set = "set unixsocketperm '${unixsocketperm}'"
  }

  #-----------------------------------------------------------------------------
  # REDIS
  #-----------------------------------------------------------------------------
  # We want to create the file and, if applicable, put the initial slaveof config in
  # (we don't want augeas managing that, since sentinel will be setting it on failover and managing the role from then on)

  # The command used to create the redis config
  $config_create_command = "touch ${redis_config}"

  exec { "create ${redis_config}":
    command => $config_create_command,
    creates => $redis_config,
    require => Package['redis-server'],
  }

  file { $redis_config:
    ensure  => present,
    owner   => 'redis',
    group   => 'redis',
    mode    => '0640',
    require => [Package['redis-server'], Exec["create ${redis_config}"]],
  }

  # Augeas is required, because /etc/redis/redis-server-<INSTANCE>.conf could
  # be changed at any time by Redis
  augeas { "update ${redis_config}":
    changes => [
      "set #comment[1] '${redis_name}'",
      "set daemonize 'yes'",
      "set pidfile '/var/run/redis/redis-server-${redis_name}.pid'",
      "set bind '${ip}'",
      "set port '${port}'",
      "set tcp-backlog '${tcp_backlog}'", # new
      "set timeout '${timeout}'",
      "set tcp-keepalive '${tcp_keepalive}'",
      # Note: i used log_level because loglevel is a puppet metaparam
      "set loglevel '${log_level}'",
      "set logfile '/var/log/redis/redis-server-${redis_name}.log'",
      "set databases '${databases}'",
      "set stop-writes-on-bgsave-error '${stop_writes_on_bgsave_error_value}'",
      "set rdbcompression '${rdbcompression_value}'",
      $masterauth_set,
      $unixsocket_set,
      $unixsocketperm_set,
      "set rdbchecksum '${rdbchecksum_value}'",
      "set dbfilename 'dump.rdb'",
      "set dir '${redis_cluster::redis_instances_path}/${redis_name}/'",
      "set slave-serve-stale-data '${slave_serve_stale_data_value}'",
      "set slave-read-only '${slave_read_only_value}'",
      "set repl-diskless-sync 'no'", # It is experimental. Disabled.
      "set repl-diskless-sync-delay '5'",
      "set repl-ping-slave-period '${repl_ping_slave_period}'",
      "set repl-timeout '${repl_timeout}'",
      "set repl-disable-tcp-nodelay '${repl_disable_tcp_nodelay_value}'",
      "set repl-backlog-size '${repl_backlog_size}'",
      "set repl-backlog-ttl '${repl_backlog_ttl}'",
      "set slave-priority '${slave_priority}'",
      "set maxclients '${maxclients}'",
      $maxmemory_set,
      $requirepass_set,
      "set maxmemory-policy '${maxmemory_policy}'",
      "set appendonly '${appendonly_value}'",
      "set appendfilename 'appendonly.aof'",
      "set appendfsync '${appendfsync}'",
      "set no-appendfsync-on-rewrite '${no_appendfsync_on_rewrite_value}'",
      "set auto-aof-rewrite-percentage '${auto_aof_rewrite_percentage}'",
      "set auto-aof-rewrite-min-size '${auto_aof_rewrite_min_size}'",
      "set aof-load-truncated 'yes'", # new
      "set lua-time-limit '${lua_time_limit}'",
      "set cluster-enabled '${cluster_enabled_value}'", # new
      "set cluster-config-file '${redis_cluster::redis_instances_path}/${redis_name}/autogen-nodes.conf'",
      "set cluster-node-timeout '${redis_cluster::cluster_node_timeout}'",
      "set slowlog-log-slower-than '${slowlog_log_slower_than}'",
      "set slowlog-max-len '${slowlog_max_len}'",
      "set latency-monitor-threshold '${latency_monitor_threshold}'",
      'rm notify-keyspace-events',
      "set hash-max-ziplist-entries '${hash_max_ziplist_entries}'",
      "set hash-max-ziplist-value '${hash_max_ziplist_value}'",
      "set list-max-ziplist-entries '${list_max_ziplist_entries}'",
      "set list-max-ziplist-value '${list_max_ziplist_value}'",
      "set set-max-intset-entries '${set_max_intset_entries}'",
      "set zset-max-ziplist-entries '${zset_max_ziplist_entries}'",
      "set zset-max-ziplist-value '${zset_max_ziplist_value}'",
      "set hll-sparse-max-bytes '${hll_sparse_max_bytes}'",
      "set activerehashing '${activerehashing_value}'",
      "set min-slaves-to-write '${min_slaves_to_write}'",
      "set min-slaves-max-lag '${min_slaves_max_lag}'",
      #"set client-output-buffer-limit 'normal 0 0 0'",
      #"set client-output-buffer-limit 'slave 256mb 64mb 60'",
      #"set client-output-buffer-limit 'pubsub 32mb 8mb 60'",
      "set hz '${hz}'",
      "set aof-rewrite-incremental-fsync '${aof_rewrite_incremental_fsync_value}'",
    ],
    lens    => 'Redis.lns',
    context => "/files${redis_config}",
    incl    => $redis_config,
    require => File[$redis_config],
  }

  if $save_enabled == true {
    # TODO add the possibility to change the save content with a table like
    # this: [[600, 1], [300, 100], [60, 10000]]
    augeas { "update ${redis_config} (save section)":
      changes => [
        "set save[1]/seconds '600'",
        "set save[1]/keys '1'",
        "set save[2]/seconds '300'",
        "set save[2]/keys '100'",
        "set save[3]/seconds '60'",
        "set save[3]/keys '10000'",
      ],
      lens    => 'Redis.lns',
      context => "/files${redis_config}",
      incl    => $redis_config,
      require => [Class['::redis_cluster'], File[$redis_config]],
    }
  } else {
    augeas { "update ${redis_config} (save section)":
      changes => [
        'rm save[1]',
        'rm save[2]',
        'rm save[3]',
      ],
      lens    => 'Redis.lns',
      context => "/files${redis_config}",
      incl    => $redis_config,
      require => [Class['::redis_cluster'], File[$redis_config]],
    }
  }

  redis_cluster::instance::service {$redis_name:
    redis_port => $redis_port,
    require    =>  [Class['::redis_cluster::load_instances'],
                    Augeas["update ${redis_config}"]],
  }
}

# vim:ft=puppet:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8:foldmethod=marker
