define sysctl::limits (
  $domain,
  $type,
  $item,
  $value,
  $target = '/etc/security/limits.conf',
  $ensure = present
) {
  # validate parameters
  validate_string($domain, $target)
  validate_re($type, '^(-|soft|hard)$')
  validate_re($item, '^(core|data|fsize|memlock|nofile|rss|stack|cpu|nproc|as|maxlogins|maxsyslogins|priority|locks|sigpending|msgqueue|nice|rtprio)$')
  if $value != 'unlimited' {
    validate_integer($value)
  }
  validate_re($ensure, '^(present|absent)$')

  if is_absolute_path($target) {
    # define augeas specific variables
    $key = "${domain}/${type}/${item}"
    $path_list  = "domain[.=\"${domain}\"][./type=\"${type}\" and ./item=\"${item}\"]"
    $path_exact = "domain[.=\"${domain}\"][./type=\"${type}\" and ./item=\"${item}\" and ./value=\"${value}\"]"

    # manage file
    if !defined(File[$target]) {
      file {
        $target :
          ensure => $ensure,
          owner => 0,
          group => 0,
          mode => '0644' ;
      }
    }

    # defaults
    Augeas {
      incl => $target,
      lens => 'Limits.lns',
      require => File[$target],
    }

    # manage with augeas
    case $ensure {
      present : {
        # actually create an entry
        augeas {
          "sysctlLimits_${name}":
            onlyif  => "match ${path_exact} size != 1",
            changes => [
              "rm ${path_list}", # remove all matching to the $domain, $type, $item, for any $value
              "set domain[last()+1] ${domain}", # insert new node at the end of tree
              # assign values to the new node
              "set domain[last()]/type ${type}",
              "set domain[last()]/item ${item}",
              "set domain[last()]/value ${value}",
            ] ;
        }
      }

      absent : {
        # actually remove an entry
        augeas {
          "sysctlLimits_${name}":
            onlyif  => "match ${path_exact} size == 1",
            changes => [
              "rm ${path_list}", # remove all matching to the $domain, $type, $item, for any $value
            ] ;
        }
      }
    }
  } else {
    # create single limits.d file
    file {
      "/etc/security/limits.d/${name}.conf" :
        ensure => $ensure,
        content => template("sysctl/limits.d.conf.erb"),
        owner => 0,
        group => 0,
        mode => '0644' ;
    }
  }
}
