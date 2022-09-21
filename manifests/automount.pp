#
# @summary Install freeipa automount
#
# @example
#   include freeipa::automount


class freeipa::automount (Hash $options) {

  file { '/etc/ipa/client_automount.sh':
    content => stdlib::deferrable_epp(
      'freeipa/client_automount.sh.epp',
      {'options' => $options}
    ),
    ensure  => present,
    owner   => 'root',
    mode    => '0500',
    notify  => Exec['freeipa_client_automount'],
    require => Package[$freeipa::ipa_client_package_name],
  }

  exec { 'freeipa_client_automount':
    command => '/etc/ipa/client_automount.sh',
    timeout => 0,
    unless  => "grep 'services.*autofs' /etc/sssd/sssd.conf",
    require => Class['Freeipa::install::client'],
    logoutput => 'on_failure',
    before    => Service['sssd'],
  }

}
