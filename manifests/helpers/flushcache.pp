#
# @summary Flushcache sss for Debian and RedHat only
#
# @example
#   include freeipa::helpers::flushcache
#
class freeipa::helpers::flushcache (String $cmd) {

  exec { "ipa_flushcache":
    command     => "/bin/bash -c ${cmd}",
    returns     => ['0','1','2'],
    notify      => Service['sssd'],
    refreshonly => true,
  }

}
