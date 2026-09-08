# Reference

## `freeipa::client`

Enrolls a supported Ubuntu or Debian 13 host with FreeIPA and manages SSSD after
successful enrollment.

```puppet
class freeipa::client (
  Stdlib::Fqdn           $domain,
  Stdlib::Fqdn           $server,
  String[1]              $principal,
  Sensitive[String]      $password,
  Boolean                $mkhomedir       = true,
  Optional[Stdlib::Fqdn] $hostname        = undef,
  String[1]              $package_name    = 'freeipa-client',
  Integer[60, 3600]      $install_timeout = 1800,
)
```

Only Ubuntu 24.04, Ubuntu 26.04, and Debian 13 are supported. Existing
enrollment is validated, not modified. See README for the credential and
process-inspection boundary.
