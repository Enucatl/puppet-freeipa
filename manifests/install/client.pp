#
# @summary Install freeipa client
#
# @example
#   include freeipa::install::client
#
#
class freeipa::install::client (Hash $options) {

  package{ $freeipa::ipa_client_package_name:
    ensure => present,
  }

  $install_script = '/etc/ipa/client_install.sh'

  file { $install_script:
    content    => stdlib::deferrable_epp(
      'freeipa/client_install.sh.epp',
      {'options' => $options}
    ), 
    ensure     => present,
    owner      => 'root',
    mode       => '0500',
    notify     => Exec['freeipa_client_install'],
  }

  exec { 'freeipa_client_install':
    command   => '/etc/ipa/client_install.sh',
    timeout   => 0,
    unless    => 'test -f /etc/ipa/default.conf',
    creates   => '/etc/ipa/default.conf',
    logoutput => 'on_failure',
    before    => Service['sssd'],
  }

  service { 'sssd':
    ensure  => 'running',
    enable  => true,
    require => Package[$freeipa::sssd_package_name],
  }

}
