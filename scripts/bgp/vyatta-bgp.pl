#!/usr/bin/perl
use lib "/opt/vyatta/share/perl5/";
use Vyatta::Config;
use Vyatta::Misc;
use Getopt::Long;

GetOptions("check-peer-name=s"      => \$peername,
	   "check-as"		    => \$checkas,
	   "check-peer-groups"	    => \$checkpeergroups,
	   "check-if-peer-group"    => \$checkifpeergroup,
           "peergroup=s"    	    => \$pg,
           "as=s"		    => \$as,
           "neighbor=s"		    => \$neighbor,
);

if    (defined $peername) 	 	{ check_peer_name($peername); }
elsif (defined $checkpeergroups &&
       defined $pg &&
       defined $as) 			{ check_for_peer_groups($pg, $as); }
elsif (defined $neighbor && 
       defined $as && 
       defined $checkas && 
       defined $pg) 		 	{ check_as($pg, $neighbor, $as); }
elsif (defined $neighbor && 
       defined $as && 
       defined $checkas)  	 	{ check_as(-1, $neighbor, $as); }
elsif (defined $pg &&
       defined $checkifpeergroup)       { check_if_peer_group($pg); }


exit 0;

sub check_if_peer_group {
    my $neighbor = shift;

    my $version = is_ip_v4_or_v6($neighbor);
    exit 1 if defined $version;
    exit 0;
}


# Make sure the neighbor is a proper IP or name
sub check_peer_name() {
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
sub check_for_peer_groups() {
  my $config = new Vyatta::Config;
  my $pg = shift;
  my $as = shift;
  my $node = $pg;
  my @peers, @neighbors;

  # short circuit if the neighbor is an IP rather than name
  my $version = is_ip_v4_or_v6($node);
  return if defined $version;

  # get the list of neighbors and see if they have a peer-group set
  $config->setLevel("protocols bgp $as neighbor");
  my @neighbors = $config->listNodes();
  
  foreach $node (@neighbors) { 
    my $peergroup = $config->returnValue("$node peer-group");
    if ($peergroup eq $pg) { push @peers, $node; }
  }

  # if we found peers in the previous statements
  # notify an return errors
  if (@peers) { 
    foreach $node (@peers) {
      print "neighbor $node uses peer-group $pg\n";
    }
    
    print "please delete these peers before removing the peer-group\n";
    exit 1;
  }

  return;
}

# make sure nodes are either in a peer group of have
# a remote AS assigned to them.  
sub check_as() {
  my $pg = shift;
  my $neighbor = shift;
  my $as = shift;
  my $config = new Vyatta::Config;
  my $pgtest = $neighbor;

  # if this is peer-group then short circuit this
  my $version = is_ip_v4_or_v6($node);
  return if ! defined $version;

  $config->setLevel("protocols bgp $as neighbor $neighbor");
  $remoteas = $config->returnValue("remote-as");

  if (! defined $remoteas) {
    if ($pg > 0) { 
      $peergroup = 1; 
      $peergroupas = 1;
    }
    else { 
      $peergroup = $config->returnValue("peer-group"); 
      $peergroupas = $config->returnValue(" .. $peergroup remote-as");
    }

    if (! defined $peergroup) {
      print "protocols bgp $as neighbor $neighbor: you must define a remote-as or peer-group\n";
      exit 1;
    }

    if (! defined $peergroupas) {
      print "protocols bgp $as neighbor $neighbor: you must define a remote-as in this neighbor or in peer-group $peergroup\n";
      exit 1;
    }
  }

  return;
}
