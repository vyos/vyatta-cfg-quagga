#!/usr/bin/perl
use lib "/opt/vyatta/share/perl5/";
use VyattaConfig;
use VyattaMisc;
use Getopt::Long;

GetOptions("check-peer-name=s"      => \$peername,
	   "check-as"		    => \$checkas,
	   "check-peer-groups"	    => \$checkpeergroups,
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


exit 0;

# Make sure the neighbor is a proper IP or name
sub check_peer_name() {
  my $neighbor = shift;

  $_ = $neighbor;
  if ((! isIpAddress("$neighbor")) && (/[\s\W]/g)) { 
    print "malformed neighbor address $neighbor\n";
    exit 1;
  }
  
  # Quagga treats the first byte as a potential IPv6 address
  # so we can't use it as a peer group name.  So let's check for it.
  if (/^[A-Fa-f]{1,4}$/) {
    print "malformed neighbor address $neighbor\n";
    exit 1;
  }
}

# Make sure we aren't deleteing a peer-group that has 
# neighbors configured to us it
sub check_for_peer_groups() {
  my $config = new VyattaConfig;
  my $pg = shift;
  my $as = shift;
  my $node = $pg;
  my @peers, @neighbors;

  # short circuit if the neighbor is an IP rather than name
  $node =~ s/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}//;
  if ($node eq "") { return; }

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
  my $config = new VyattaConfig;
  my $pgtest = $neighbor;

  # if this is peer-group then short circuit this
  $pgtest =~ s/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}//;
  if ($pgtest ne "") { return; }

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
      print "You must define a remote-as or peer-group for neighbor $neighbor before commiting\n";
      exit 1;
    }

    if (! defined $peergroupas) {
      print "You must define a remote-as in neighbor $neighbor or peer-group $peergroup before commiting\n";
      exit 1;
    }
  }

  return;
}
