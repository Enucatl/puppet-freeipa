# Changelog

## 7.1.0

- Enroll Debian 13 hosts with the same `freeipa::client` class used on Ubuntu
  24.04 and 26.04. Debian point releases such as 13.6 match on major version 13.

## 7.0.0

### Breaking

- Support only Puppet 8 clients on Ubuntu 24.04 and 26.04.
- Replace all former public APIs with `freeipa::client`.
- Remove server, replica, automount, cache-flush, role fact, and admin task
  management. FreeIPA servers remain externally managed.

### Security

- Enroll through a native provider using direct argv execution and a finite
  timeout.
- Keep the password sensitive until agent-side execution and redact failures.
- Refuse to replace an existing mismatched or malformed enrollment.
