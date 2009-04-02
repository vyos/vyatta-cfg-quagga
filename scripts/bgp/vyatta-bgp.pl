#!/usr/bin/perl
use strict;
use lib "/opt/vyatta/share/perl5/";
use Vyatta::Config;
use Vyatta::Misc;
use Getopt::Long;

my ( $pg, $as, $neighbor );
my ( $checkas, $peername, $checkifpeergroup, $checkpeergroups );

GetOptions(
    "peergroup=s"         => \$pg,
    "as=s"                => \$as,
    "neighbor=s"          => \$neighbor,
    "check-peer-name=s"   => \$peername,
    "check-as"            => \$checkas,
    "check-peer-groups"   => \$checkpeergroups,
    "check-if-peer-group" => \$checkifpeergroup,
);

check_peer_name($peername)	  	if ($peername);
check_for_peer_groups( $pg, $as )	if ($checkpeergroups);
check_as( $neighbor, $as, $pg ) 	if ($checkas);
check_if_peer_group($pg)		if ($checkifpeergroup);

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
    if ( ( !defined($version) ) && (/[\s\W]/g) ) {
        die "malformed neighbor address $neighbor\n";
    }

    # Quagga treats the first byte as a potential IPv6 address
    # so we can't use it as a peer group name.  So let's check for it.
    if ( $version == 6 && /^[A-Fa-f]{1,4}$/ ) {
	die "malformed neighbor address $neighbor\n";
    }
}

# Make sure we aren't deleteing a peer-group that has
# neighbors configured to us it
sub check_for_peer_groups {
    my $config = new Vyatta::Config;
    my $pg     = shift;
    die "Peer group not defined\n" unless $pg;
    my $as = shift;
    die "AS not defined\n" unless $as;
    my @peers;

    # short circuit if the neighbor is an IP rather than name
    return if is_ip_v4_or_v6($pg);

    # get the list of neighbors and see if they have a peer-group set
    $config->setLevel("protocols bgp $as neighbor");
    my @neighbors = $config->listNodes();

    foreach my $node (@neighbors) {
        my $peergroup = $config->returnValue("$node peer-group");
        if ( $peergroup eq $pg ) { push @peers, $node; }
    }

    # if we found peers in the previous statements
    # notify an return errors
    if (@peers) {
        foreach my $node (@peers) {
            print "neighbor $node uses peer-group $pg\n";
        }

	die "please delete these peers before removing the peer-group\n";
    }
}

# make sure nodes are either in a peer group or have
# a remote AS assigned to them.
sub check_as {
    my ($neighbor, $as, $pg) = @_;

    die "neighbor not defined\n" unless $neighbor;
    die "AS not defined\n" unless $as;

    # if this is peer-group then short circuit this
    return if ! is_ip_v4_or_v6($neighbor); 

    my $config = new Vyatta::Config;
    $config->setLevel("protocols bgp $as neighbor $neighbor");
    my $remoteas = $config->returnValue("remote-as");
    return if defined $remoteas;

    return if $pg;

    my $peergroup   = $config->returnValue("peer-group");
    die "protocols bgp $as neighbor $neighbor: must define a remote-as or peer-group\n"
      unless $peergroup;

    my $peergroupas = $config->returnValue(" .. $peergroup remote-as");
    die "protocols bgp $as neighbor $neighbor: must define a remote-as in neighbor or peer-group $peergroup\n"
      unless $peergroupas;
}
