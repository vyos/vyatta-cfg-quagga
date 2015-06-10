#!/usr/bin/perl
use Getopt::Long;
use strict;

my ($iface, $dhcp, $route, $table, $nip, $oip, $nrouters, $orouters, $reason);
GetOptions("interface=s"    => \$iface,
           "dhcp=s"         => \$dhcp,
           "route=s"        => \$route,
           "table=s"        => \$table,
           "new_ip=s"       => \$nip,
           "old_ip=s"       => \$oip,
           "new_routers=s"  => \$nrouters,
           "old_routers=s"  => \$orouters,
           "reason=s"       => \$reason);

# check if an update is needed
if (($reason eq "BOUND") || ($reason eq "REBOOT")) {
    $oip      = "";
    $orouters = "";
}
exit(0) if (($iface ne $dhcp) || (($oip eq $nip) && ($orouters eq $nrouters)));
logger("DHCP address on $iface updated to $nip,$nrouters from $oip,$orouters: Updating static route $route in table $table.");
my $tab;
if ($table eq "main") {
    $tab = "";
}
else {
    $tab = "table $table";
}
if ($orouters ne $nrouters) {
    if ($orouters ne "") {
        system("vtysh -c 'configure terminal' -c 'no ip route $route $orouters $tab' ");
    }
    if (($nrouters ne "") && ($nrouters ne "127.0.0.1")) {
        system("vtysh -c 'configure terminal' -c 'ip route $route $nrouters $tab' ");
    }
}
if (($oip ne $nip) && ($table ne "main") && ($route eq "0.0.0.0/0")) {
    my $mark = 0x7fffffff + $table;
    if ($oip ne "") {
        system("sudo /sbin/iptables -t mangle -D OUTPUT -s $oip/32 -j MARK --set-mark $mark");
    }
    if (($nip ne "") && ($nip ne "127.0.0.1")) {
        system("sudo /sbin/iptables -t mangle -D OUTPUT -s $nip/32 -j MARK --set-mark $mark");
        system("sudo /sbin/iptables -t mangle -I OUTPUT -s $nip/32 -j MARK --set-mark $mark");
    }
}

sub logger {
  my $msg = pop(@_);
  my $FACILITY = "daemon";
  my $LEVEL = "notice";
  my $TAG = "tunnel-dhclient-hook";
  my $LOGCMD = "logger -t $TAG -p $FACILITY.$LEVEL";
  system("$LOGCMD $msg");
}
