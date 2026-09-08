# freeipa

Puppet 8 module for enrolling FreeIPA clients on Ubuntu 24.04, Ubuntu 26.04,
and Debian 13.
Version 7 is client-only and intentionally removes every server, replica,
automount, and administrative API from earlier releases. FreeIPA server
lifecycle belongs outside this module (for example, in Docker Compose).

## Usage

```puppet
class { 'freeipa::client':
  domain    => 'example.test',
  server    => 'ipa.example.test',
  principal => 'puppet-enroller',
  password  => Sensitive('use Hiera or another secret backend'),
}
```

The class installs only `freeipa-client`, enrolls through a native provider,
then enables and starts SSSD. `mkhomedir` defaults to `true`. Set `hostname`
only when enrollment must use a name other than the host default.

Enrollment is intentionally one-way. If `/etc/ipa/default.conf` is absent,
the provider runs `ipa-client-install --unattended` with a direct argument
array and a finite timeout. If the file exists, normalized `domain`, `server`,
and a requested `hostname` must match. Missing or mismatched data fails the
run without uninstalling or re-enrolling the client. These parameters do not
continuously reconfigure FreeIPA after enrollment.

## Parameters

- `domain`: FreeIPA DNS domain.
- `server`: FreeIPA server FQDN.
- `principal`: enrollment principal; use a dedicated least-privilege account.
- `password`: `Sensitive[String]` enrollment password.
- `mkhomedir`: pass `--mkhomedir`; default `true`.
- `hostname`: optional enrollment hostname.
- `package_name`: client package; default `freeipa-client`.
- `install_timeout`: 60–3600 seconds; default 1800.

## Security boundary

Puppet marks the password sensitive, and the provider unwraps it only on the
agent immediately before execution. It never writes a credential-bearing
script, invokes a shell, or includes installer output in failure reports.

The password still exists in the compiled catalog and is briefly present in
the privileged local process argument list while `ipa-client-install` runs.
Protect Puppet Server/PuppetDB data and local root access. Use a rotated,
non-expiring account limited to host creation and enrollment; never distribute
the FreeIPA `admin` password to clients.

## Development

```console
bundle install
bundle exec rake validate lint spec
bundle exec rubocop
```

Acceptance testing requires disposable privileged AlmaLinux 10 FreeIPA and
Ubuntu 24.04/26.04 or Debian 13 systemd machines. It must verify enrollment, the
host keytab, identity lookup, SSSD, a zero-change second run, and safe failure
on a requested domain/server mismatch.
