#
# @summary Manages IPA masters, replicas and clients.
#
# @example
#    include freeipa
#
#
class freeipa (
  String $ipa_server_package_name,
  String $ipa_client_package_name,
  String $ldaputils_package_name,
  String $sssd_package_name,
  String $sssdtools_package_name,
  String $autofs_package_name,
) {
  if $facts['kernel'] != 'Linux' or $facts['osfamily'] == 'Windows' {
    fail('This module is only supported on Linux.')
  }

  package { $freeipa::ldaputils_package_name:
    ensure => present,
  }

  package { $freeipa::sssd_package_name:
    ensure => present,
  }

  package { $freeipa::sssdtools_package_name:
    ensure => present,
  }

  package { $freeipa::autofs_package_name:
    ensure => present,
  }

  service { 'sssd':
    ensure  => 'running',
    enable  => true,
    require => Package[$freeipa::sssd_package_name],
  }

}
