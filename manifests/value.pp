# Manage sysctl value
#
# It not only manages the entry within
# /etc/sysctl.conf, but also checks the
# current active version.
#
# Parameters
#
# * value: to set.
# * key Key to set, default: $name
# * target: an alternative target for your sysctl values.
define sysctl::value (
  $value,
  $key    = $name,
  $target = undef,
  $ensure = present
) {
  require sysctl::base
  $val1 = inline_template("<%= String(@value).split(/[\s\t]/).reject(&:empty?).flatten.join(\"\t\") %>")

  sysctl { $key :
    ensure => $ensure,
    val    => $val1,
    target => $target,
    before => Sysctl_runtime[$key],
  }

  if $ensure == 'present' {
    # reload sysctl in rc.local
    include sysctl::onboot
   
    # execute change
    sysctl_runtime { $key:
      val => $val1,
    }
  }
}
