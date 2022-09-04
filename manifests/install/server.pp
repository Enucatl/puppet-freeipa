#
# @summary This class mainly defines options for the ipa install command, then install master or replica regarding the role set.
#
# @example
#   include freeipa::install::server
#
#
class freeipa::install::server (Hash $options) {

  package { $freeipa::ipa_server_package_name:
    ensure => present,
  }

  service { 'httpd':
    ensure => 'running',
    enable => true,
  }

  file { '/etc/ipa/server_install.sh':
    content    => stdlib::deferrable_epp(
      'freeipa/server_install.sh.epp',
      {'options' => $options}
    ), 
    ensure     => present,
    owner      => 'root',
    mode       => '0500',
    notify     => Exec['freeipa_server_install'],
  }

  exec { 'freeipa_server_install':
    command   => '/etc/ipa/server_install.sh',
    timeout   => 0,
    unless    => '/usr/sbin/ipactl status > /dev/null 2>&1',
    creates   => '/etc/ipa/default.conf',
    logoutput => 'on_failure',
    notify    => Class['Freeipa::Helpers::Flushcache'],
    before    => Service['sssd'],
  }

  service { 'ipa':
    ensure  => 'running',
    enable  => true,
    require => Exec['freeipa_server_install'],
  }

  service { 'sssd':
    ensure  => 'running',
    enable  => true,
    require => Package[$freeipa::sssd_package_name],
  }

  contain freeipa::helpers::flushcache

}
