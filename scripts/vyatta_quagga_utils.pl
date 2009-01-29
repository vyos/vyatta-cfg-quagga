#!/usr/bin/perl
use strict;
use lib "/opt/vyatta/share/perl5/";
use Vyatta::Config;
use Vyatta::Misc;
use NetAddr::IP;
use Getopt::Long;

GetOptions("check-prefix-boundry=s" => sub { check_prefix_boundry( $_[1] ); },
           "not-exists=s"           => sub { check_not_exists($_[1]); },
	   "exists=s"		    => sub { check_exists($_[1]); },
	   "check-ospf-area=s"      => sub { check_ospf_area($_[1]); },
);

exit 0;

sub check_prefix_boundry {
  my $prefix = shift;
  my ($net, $network, $cidr);

  $net = new NetAddr::IP $prefix;
  $network = $net->network();
  $cidr    = $net->cidr();

  die "Your prefix must fall on a natural network boundry.  ", 
       "Did you mean $network?\n"
      if ($cidr ne $network);
  
  exit 0;
}

sub check_exists {
  my $node = shift;
  my $config = new Vyatta::Config;

  exit 0 if $config->exists($node);
  exit 1;
}

sub check_not_exists {
  my $node = shift;
  my $config = new Vyatta::Config;

  exit 0 if ! $config->exists($node);
  exit 1;
}

sub check_ospf_area {
    my $area = shift;

    #
    # allow both decimal or dotted decimal 
    #
    if ($area =~ m/^\d+$/) {
	if ($area >= 0 && $area <= 4294967295) {
	    exit 0;
	}
    }
    if ($area =~ m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
	foreach my $octet ($1, $2, $3, $4) {
	    if (($octet < 0) || ($octet > 255)) { exit 1; }
	}
	exit 0
    }
    exit 1;
}

