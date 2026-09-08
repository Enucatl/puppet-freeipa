# @summary Enrolls an Ubuntu or Debian 13 host as a FreeIPA client.
#
# Enrollment parameters are used only when /etc/ipa/default.conf is absent.
# Existing enrollment that does not match the requested domain, server, or
# hostname fails safely and is never replaced automatically.
class freeipa::client (
  Stdlib::Fqdn           $domain,
  Stdlib::Fqdn           $server,
  String[1]              $principal,
  Sensitive[String]      $password,
  Boolean                $mkhomedir       = true,
  Optional[Stdlib::Fqdn] $hostname        = undef,
  String[1]              $package_name    = 'freeipa-client',
  Integer[60, 3600]      $install_timeout = 1800,
) {
  $os_name = $facts['os']['name']
  $os_full = $facts['os']['release']['full']
  $ubuntu_supported = $os_name == 'Ubuntu' and $os_full in ['24.04', '26.04']
  $debian_supported = $os_name == 'Debian' and $facts['os']['release']['major'] == '13'
  unless $ubuntu_supported or $debian_supported {
    fail("freeipa::client supports only Ubuntu 24.04, Ubuntu 26.04, and Debian 13; got ${os_name} ${os_full}")
  }

  package { $package_name:
    ensure => installed,
  }

  freeipa_client_enrollment { 'default':
    ensure          => present,
    domain          => $domain,
    server          => $server,
    principal       => $principal,
    password        => $password,
    mkhomedir       => $mkhomedir,
    hostname        => $hostname,
    install_timeout => $install_timeout,
    require         => Package[$package_name],
    before          => Service['sssd'],
  }

  service { 'sssd':
    ensure => running,
    enable => true,
  }
}
