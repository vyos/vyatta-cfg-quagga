#!/usr/bin/perl
use Getopt::Long;
use strict;

my ($iface, $dhcp, $route, $table, $nip, $oip, $reason);
GetOptions("interface=s"    => \$iface,
           "dhcp=s"         => \$dhcp,
           "route=s"        => \$route,
           "table=s"        => \$table,
           "new_routers=s"  => \$nrouters,
           "old_routers=s"  => \$orouters,
           "reason=s"       => \$reason);

# check if an update is needed
exit(0) if (($iface ne $dhcp) || ($orouters eq $nrouters) || ($reason ne "BOUND"));
logger("DHCP address on $iface updated to $nip from $oip: Updating static route $route in table $table.");
if ($table eq "main") {
    $table = "";
}
else {
    $table = "table $table";
}
system("vtysh -c 'configure terminal' -c 'ip route $route $nrouters $table' ");

sub logger {
  my $msg = pop(@_);
  my $FACILITY = "daemon";
  my $LEVEL = "notice";
  my $TAG = "tunnel-dhclient-hook";
  my $LOGCMD = "logger -t $TAG -p $FACILITY.$LEVEL";
  system("$LOGCMD $msg");
}
