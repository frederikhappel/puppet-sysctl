class sysctl::onboot {
  # enable /etc/sysctl.conf setting during boot
  file_line {
    'sysctlOnboot_reload' :
      line => '/sbin/sysctl -p /etc/sysctl.conf',
      path => '/etc/rc.local' ;
  }
}
