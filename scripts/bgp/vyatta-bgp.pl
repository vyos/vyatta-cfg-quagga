#!/usr/bin/perl
use strict;
use lib "/opt/vyatta/share/perl5/";
use Vyatta::Config;
use Vyatta::Misc;
use Getopt::Long;

my $pg = -1;
my ($as, $neighbor);

GetOptions(
    "peergroup=s"    	    => \$pg,
    "as=s"		    => \$as,
    "neighbor=s"	    => \$neighbor,
    "check-peer-name=s"     => sub { check_peer_name( $_[1] ) },
    "check-as"		    => sub { check_as($pg, $neighbor, $as); },
    "check-peer-groups"	    => sub { check_for_peer_groups($pg, $as); },
    "check-if-peer-group"   => sub { check_if_peer_group($pg); },
);

exit 0;

sub check_if_peer_group {
    my $neighbor = shift;
    
    exit 1 if is_ip_v4_or_v6($neighbor);
    exit 0;
}


# Make sure the neighbor is a proper IP or name
sub check_peer_name {
  my $neighbor = shift;

  $_ = $neighbor;
  my $version = is_ip_v4_or_v6($neighbor);
  if ((!defined($version)) && (/[\s\W]/g)) { 
    print "malformed neighbor address $neighbor\n";
    exit 1;
  }
  
  # Quagga treats the first byte as a potential IPv6 address
  # so we can't use it as a peer group name.  So let's check for it.
  if ($version == 6 && /^[A-Fa-f]{1,4}$/) {
    print "malformed neighbor address $neighbor\n";
    exit 1;
  }
}

# Make sure we aren't deleteing a peer-group that has 
# neighbors configured to us it
sub check_for_peer_groups {
  my $config = new Vyatta::Config;
  my $pg = shift;
  my $as = shift;
  my @peers;

  # short circuit if the neighbor is an IP rather than name
  return if is_ip_v4_or_v6($pg);

  # get the list of neighbors and see if they have a peer-group set
  $config->setLevel("protocols bgp $as neighbor");
  my @neighbors = $config->listNodes();
  
  foreach my $node (@neighbors) { 
    my $peergroup = $config->returnValue("$node peer-group");
    if ($peergroup eq $pg) { push @peers, $node; }
  }

  # if we found peers in the previous statements
  # notify an return errors
  if (@peers) { 
    foreach my $node (@peers) {
      print "neighbor $node uses peer-group $pg\n";
    }
    
    print "please delete these peers before removing the peer-group\n";
    exit 1;
  }

  return;
}

# make sure nodes are either in a peer group of have
# a remote AS assigned to them.  
sub check_as {
  my $pg = shift;
  my $neighbor = shift;
  my $as = shift;
  my $config = new Vyatta::Config;
  my $pgtest = $neighbor;

  # if this is peer-group then short circuit this
  return unless is_ip_v4_or_v6($pg);

  $config->setLevel("protocols bgp $as neighbor $neighbor");
  my $remoteas = $config->returnValue("remote-as");

  return unless $remoteas;

  return if ($pg > 0);

  my $peergroup = $config->returnValue("peer-group"); 
  my $peergroupas = $config->returnValue(" .. $peergroup remote-as");

  die "protocols bgp $as neighbor $neighbor: must define a remote-as or peer-group\n"
      unless $peergroup;

  die "protocols bgp $as neighbor $neighbor: must define a remote-as in neighbor or peer-group $peergroup\n"
      unless $peergroupas;
}
