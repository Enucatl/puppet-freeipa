#
# @summary Install freeipa client
#
# @example
#   include freeipa::install::client


class freeipa::install::client (Hash $options) {

  if $facts['os']['family'] == 'Debian' and $facts['os']['name'] == 'Debian' {
    class { 'apt::backports':
      repos => 'main',
      before => Package[$freeipa::ipa_client_package_name],
    }
  }

  package{ $freeipa::ipa_client_package_name:
    ensure => present,
  }

  file { '/etc/ipa/client_install.sh':
    content => stdlib::deferrable_epp(
      'freeipa/client_install.sh.epp',
      {'options' => $options}
    ), 
    ensure  => present,
    owner   => 'root',
    mode    => '0500',
    notify  => Exec['freeipa_client_install'],
    require => Package[$freeipa::ipa_client_package_name],
  }

  exec { 'freeipa_client_install':
    command   => '/etc/ipa/client_install.sh',
    timeout   => 0,
    creates   => '/etc/ipa/default.conf',
    logoutput => 'on_failure',
    before    => Service['sssd'],
  }

}
