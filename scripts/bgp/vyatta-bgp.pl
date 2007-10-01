#!/usr/bin/perl
use lib "/opt/vyatta/share/perl5/";
use VyattaMisc;
use Getopt::Long;

GetOptions("check-peer-name=s"      => \$peername,
);

if (defined $peername) { check_peer_name($peername); }

exit 0;

sub check_peer_name() {
  my $neighbor = shift;

  $_ = $neighbor;
  if ((! isIpAddress("$neighbor")) && (/[\s\W]/g)) { 
    print "malformed neighbor address $neighbor\n";
    exit 1;
  }
  exit 0;
}
