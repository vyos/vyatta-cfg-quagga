#!/usr/bin/perl
use lib "/opt/vyatta/share/perl5/";
use VyattaConfig;
use VyattaMisc;
use NetAddr::IP;
use Getopt::Long;

GetOptions("check-prefix-boundry=s" => \$prefix,
           "not-exists=s"           => \$notexists,
	   "exists=s"		    => \$exists,
);

if (defined $prefix)    { check_prefix_boundry($prefix); }
if (defined $notexists) { check_not_exists($notexists); }
if (defined $exists)    { check_exists($exists); }

exit 0;

sub check_prefix_boundry() {
  my $prefix = shift;
  my $net, $cidr;

  $net = new NetAddr::IP $prefix;
  $cidr = $net->network();
  if ( "$cidr" ne "$prefix" ) {
    print "Your prefix must fall on a natural network boundry.  Did you mean $cidr?\n";
    exit 1;
  }
  
  exit 0;
}

sub check_exists() {
  my $node = shift;
  my $config = new VyattaConfig;

  if ( $config->exists("$node") ) {
    exit 0;
  }

  exit 1;
}

sub check_not_exists() {
  my $node = shift;
  my $config = new VyattaConfig;

  if (! $config->exists("$node") ) {
    exit 0;
  }

  exit 1;
}

