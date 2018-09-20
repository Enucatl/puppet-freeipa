# A description of what this class does
# Install freeipa client
# @summary A short summary of the purpose of this class
#
# @example
#   include freeipa::install::client
class freeipa::install::client {


  package{$freeipa::ipa_client_package_name:
    ensure => present,
  }

  package{$freeipa::kstart_package_name:
    ensure => present,
  }

  if $freeipa::client_install_ldaputils {
    package { $freeipa::ldaputils_package_name:
      ensure => present,
    }
  }

  if $freeipa::mkhomedir {
    $client_install_cmd_opts_mkhomedir = '--mkhomedir'
  } else {
    $client_install_cmd_opts_mkhomedir = ''
  }

  if $freeipa::fixed_primary {
    $client_install_cmd_opts_fixed_primary = '--fixed-primary'
  } else {
    $client_install_cmd_opts_fixed_primary = ''
  }

  if $freeipa::configure_ntp {
    $client_install_cmd_opts_no_ntp = ''
  } else {
    $client_install_cmd_opts_no_ntp = '--no-ntp'
  }

    $client_install_cmd = "\
/usr/sbin/ipa-client-install \
  --server=${freeipa::ipa_master_fqdn} \
  --realm=${freeipa::final_realm} \
  --domain=${freeipa::domain} \
  --principal='${freeipa::final_domain_join_principal}' \
  --password='${freeipa::final_domain_join_password}' \
  ${client_install_cmd_opts_mkhomedir} \
  ${client_install_cmd_opts_fixed_primary} \
  ${client_install_cmd_opts_no_ntp} \
  --unattended"

  exec { "client_install_${::fqdn}":
    command   => $client_install_cmd,
    timeout   => 0,
    unless    => "cat /etc/ipa/default.conf | grep -i \"${freeipa::domain}\"",
    creates   => '/etc/ipa/default.conf',
    logoutput => 'on_failure',
    before    => Service['sssd'],
    provider  => 'shell',
  }

  if $freeipa::install_sssd {
    service { 'sssd':
      ensure  => 'running',
      enable  => true,
      require => Package[$freeipa::sssd_package_name],
    }
  }
}
