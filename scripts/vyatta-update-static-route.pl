#!/usr/bin/perl

use Getopt::Long;
use strict;
use lib "/opt/vyatta/share/perl5";
use Vyatta::Config;

my ($iface, $route, $table, $option);
GetOptions("interface=s"    => \$iface,
           "route=s"        => \$route,
           "table=s"        => \$table,
           "option=s"       => \$option
           );
my $hash = `echo $iface $route $table | md5sum | cut -c1-10`;
my $FILE_DHCP_HOOK = "/etc/dhcp3/dhclient-exit-hooks.d/static-route-$hash";
my $dhcp_hook = '';
if ($option eq 'create') {
    $dhcp_hook =<<EOS;
#!/bin/sh
/opt/vyatta/bin/sudo-users/vyatta-static-dhcp.pl --interface=\"\$interface\" --dhcp=\"$iface\" --route=\"$route\" --table=\"$table\" --new_ip=\"\$new_ip_address\" --old_ip=\"\$old_ip_address\" --new_routers=\"\$new_routers\" --old_routers=\"\$old_routers\" --reason=\"\$reason\"
EOS
}

open my $dhcp_hook_file, '>', $FILE_DHCP_HOOK
    or die "cannot open $FILE_DHCP_HOOK";
print ${dhcp_hook_file} $dhcp_hook;
close $dhcp_hook_file;
exit 0;

