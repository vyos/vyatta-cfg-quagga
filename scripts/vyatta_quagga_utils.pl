#!/usr/bin/perl
use strict;
use lib "/opt/vyatta/share/perl5/";
use Vyatta::Config;
use Vyatta::Misc;
use NetAddr::IP;
use Getopt::Long;

my ( $prefix, $exists, $not_exists, $area, $area6, $community, $passive );

# Allowed well-know community values (see set commuinity)
my %communities = (
    'additive'   => 1,
    'internet'   => 1,
    'local-AS'   => 1,
    'no-advertise' => 1,
    'no-export'  => 1,
    'none'       => 1,
);

GetOptions(
    "check-prefix-boundry=s" => \$prefix,
    "not-exists=s"           => \$not_exists,
    "exists=s"               => \$exists,
    "check-ospf-area=s"      => \$area,
    "check-ospfv3-area=s"    => \$area6,
    "check-community"        => \$community,
    "check-ospf-passive=s"   => \$passive,
);

check_community(@ARGV)	      if ($community);
check_prefix_boundry($prefix) if ($prefix);
check_not_exists($not_exists) if ($not_exists);
check_exists($exists)         if ($exists);
check_ospfv3_area($area6)     if ($area6);
check_ospf_area($area)        if ($area);
check_ospf_passive($passive)  if ($passive);

exit 0;

sub check_prefix_boundry {
    my $prefix = shift;
    my ( $net, $network, $cidr );

    $net     = new NetAddr::IP $prefix;
    $network = $net->network()->cidr();
    $cidr    = $net->cidr();

    die "Your prefix must fall on a natural network boundry.  ",
      "Did you mean $network?\n"
      if ( $cidr ne $network );

    exit 0;
}

sub check_exists {
    my $node   = shift;
    my $config = new Vyatta::Config;

    exit 0 if $config->exists($node);
    exit 1;
}

sub check_not_exists {
    my $node   = shift;
    my $config = new Vyatta::Config;

    exit 0 if !$config->exists($node);
    exit 1;
}

sub check_ospf_area {
    my $area = shift;

    #
    # allow both decimal or dotted decimal
    #
    if ( $area =~ m/^\d+$/ ) {
        if ( $area >= 0 && $area <= 4294967295 ) {
            exit 0;
        }
    }
    if ( $area =~ m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ ) {
        foreach my $octet ( $1, $2, $3, $4 ) {
            if ( ( $octet < 0 ) || ( $octet > 255 ) ) { exit 1; }
        }
        exit 0;
    }

    die "Invalid OSPF area: $area\n";
}

sub check_ospfv3_area {
    my $area = shift;

    # allow both decimal or dotted decimal,
    # In FRR post PR#6700 it's no longer an issue
    #
    if ( $area =~ m/^\d+$/ ) {
        if ( $area >= 0 && $area <= 4294967295 ) {
            exit 0;
        }
    }

    if ( $area =~ m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ ) {
        foreach my $octet ( $1, $2, $3, $4 ) {
            if ( ( $octet < 0 ) || ( $octet > 255 ) ) { exit 1; }
        }
        exit 0;
    }

    die "Invalid OSPF area: $area\n";
}

sub check_community {
    foreach my $arg (@_) {
	next if ($arg =~ /\d+:\d+/);
	next if $communities{$arg};

	die "$arg unknown community value\n"
    }
}

sub check_ospf_passive {
    my $passive = shift;

    my $config = new Vyatta::Config;
    $config->setLevel('protocols ospf passive-interface');
    my @nodesO = $config->returnOrigValues();
    my @nodes  = $config->returnValues();
    
    my %nO_hash = map { $_ => 1 } @nodesO;
    my %n_hash  = map { $_ => 1 } @nodes;

    if ($nO_hash{'default'}) {
        exit 0 if ! $n_hash{'default'};
        print "Error: can't add interface when using 'default'\n";
        exit 1;
    } else {
        if (scalar(@nodes) > 1 and $n_hash{'default'}) {
            print "Error: delete other interfaces before using 'default'\n";
            exit 1;
        }
    }

    exit 0;
}
