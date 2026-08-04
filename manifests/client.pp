# @summary Enrolls an Ubuntu host as a FreeIPA client.
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
  unless $facts['os']['name'] == 'Ubuntu' and $facts['os']['release']['full'] in ['24.04', '26.04'] {
    fail("freeipa::client supports only Ubuntu 24.04 and 26.04; got ${facts['os']['name']} ${facts['os']['release']['full']}")
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
