#!/usr/bin/perl

# Author: Daniil Baturin <daniil@baturin.org>
# Date: 2010
# Description: OSPFv3 CLI backend

# **** License ****
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# This code was originally developed by Vyatta, Inc.
# Portions created by Vyatta are Copyright (C) 2006, 2007, 2008 Vyatta, Inc.
# All Rights Reserved.
# **** End License ****

use strict;
use warnings;

use Getopt::Long;
use NetAddr::IP::Lite;

use lib "/opt/vyatta/share/perl5/";
use Vyatta::Config;
use Vyatta::Quagga::Config;
use Vyatta::Misc;

my %quagga_commands = (
  'protocols' => {
    set => undef,
    del => undef
  },
  'protocols ospfv3' => {
    set => 'router ospf6',
    del => 'no router ospf6'
  },
  'protocols ospfv3 parameters' => {
    set => undef,
    del => undef
  },
  'protocols ospfv3 parameters router-id' => {
    set => 'router ospf6 ; router-id #5',
    del => undef
  },
  'protocols ospfv3 area' => {
    set => undef,
    del => undef
  },
  'protocols ospfv3 area var' => {
    set => undef,
    del => undef
  },
  'protocols ospfv3 area var range' => {
    set => undef,
    del => undef
  },
  'protocols ospfv3 area var range var' => {
    set => 'router ospf6 ; area #4 range #6',
    del => 'router ospf6 ; no area #4 range #6'
  },
  'protocols ospfv3 area var range var advertise' => {
    set => 'router ospf6 ; area #4 range #6 advertise',
    del => 'router ospf6 ; no area #4 range #6'
  },
  'protocols ospfv3 area var range var not-advertise' => {
    set => 'router ospf6 ; area #4 range #6 not-advertise',
    del => 'router ospf6 ; no area #4 range #6 not-advertise'
  },
  'protocols ospfv3 area var interface' => {
    set => 'router ospf6 ; no interface #6 area #4; interface #6 area #4',
    del => 'router ospf6 ; no interface #6 area #4',
    noerr => 'set'
  },
  'protocols ospfv3 area var import-list' => {
    set => 'router ospf6 ; area #4 import-list #6',
    del => 'router ospf6 ; no area #4 import-list #6'
  },
  'protocols ospfv3 area var export-list' => {
    set => 'router ospf6 ; area #4 export-list #6',
    del => 'router ospf6 ; no area #4 export-list #6'
  },
  'protocols ospfv3 area var filter-list' => {
    set => 'router ospf6 ; area #4 filter-list prefix #6',
    del => 'router ospf6 ; no area #4 filter-list prefix #6'
  },
  'protocols ospfv3 redistribute' => {
    set => undef,
    del => undef
  },
  'protocols ospfv3 redistribute connected' => {
    set => 'router ospf6 ; redistribute connected ?route-map',
    del => 'router ospf6 ; no redistribute connected'
  },
  'protocols ospfv3 redistribute kernel' => {
    set => 'router ospf6 ; redistribute kernel ?route-map',
    del => 'router ospf6 ; no redistribute kernel'
  },
  'protocols ospfv3 redistribute bgp' => {
    set => 'router ospf6 ; redistribute bgp ?route-map',
    del => 'router ospf6 ; no redistribute bgp'
  },
  'protocols ospfv3 redistribute ripng' => {
    set => 'router ospf6 ; redistribute ripng ?route-map',
    del => 'router ospf6 ; no redistribute ripng'
  },
  'protocols ospfv3 redistribute static' => {
    set => 'router ospf6 ; redistribute static ?route-map',
    del => 'router ospf6 ; no redistribute static'
  }
);

my ($main, $check_area, $area);

GetOptions(
  "main" => \$main,
  "check-area" => \$check_area,
  "area=s" => \$area
);

main()                     if ($main);
check_ospfv3_area($area)   if ($check_area);

exit 0;

sub main {
  # Create a Vyatta Quagga Config object initialized by commands mapping
  my $quagga_config = new Vyatta::Quagga::Config('protocols', \%quagga_commands);
  #$quagga_config->setDebugLevel('3');
  my @order = ('range', 'export-list', 'import-list', 'interface');
  $quagga_config->deleteConfigTreeRecursive('protocols ospfv3 area var ', undef, \@order) || die "exiting $?\n";
  $quagga_config->deleteConfigTreeRecursive('protocols ospfv3 parameters ') || die "exiting $?\n";
  $quagga_config->deleteConfigTreeRecursive('protocols ospfv3 redistribute ') || die "exiting $?\n";

  $quagga_config->setConfigTreeRecursive('protocols ospfv3 parameters ') || die "exiting $?\n";  # Priority 630
  $quagga_config->setConfigTreeRecursive('protocols ospfv3 redistribute ') || die "exiting $?\n";  # Priority 630
  $quagga_config->setConfigTreeRecursive('protocols ospfv3 area var ') || die "exiting $?\n";    # Priority 640
}

# Quagga ospf6d doesn't accept numeric area id, but requires dotted decimal. Bug 4172.
sub check_ospfv3_area {
    my $area = shift;

    if ( $area =~ m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ ) {
        foreach my $octet ( $1, $2, $3, $4 ) {
            if ( ( $octet < 0 ) || ( $octet > 255 ) ) { exit 1; }
        }
        exit 0;
    }

    die "Invalid OSPFv3 area: $area\n";
}

