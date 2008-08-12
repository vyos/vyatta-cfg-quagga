#!/usr/bin/perl -w
#
# Module: vyatta-wanloadbalance.pl
# 
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
# Portions created by Vyatta are Copyright (C) 2008 Vyatta, Inc.
# All Rights Reserved.
# 
# Author: Michael Larson
# Date: January 2008
# Description: Writes exclusion list for linkstatus
# 
# **** End License ****
#
use lib "/opt/vyatta/share/perl5/";
use VyattaConfig;
use VyattaMisc;

use warnings;
use strict;
use POSIX;
use File::Copy;

my $VTYSH='/usr/bin/vtysh';

#solution: put a commit statement in the rule node that does the action test and squirt out delete hook in rule node on a delete.

my $route_map = shift;
my $rule = shift;
my $action = shift;

if (!defined($rule) || !defined($route_map)) {
  exit 1;
}

my $config = new VyattaConfig;

$config->setLevel('policy route-map $route_map rule $rule');
if ($config->exists("action")) {
    exit 0;
}
my @qualifiers = $config->listNodes();
foreach my $qualifiers (@qualifiers) {
    exit 1; #error!
}

#need to get a count of what's left and if action is deleted, but other nodes are present then reject
    
if (-e "/tmp/delete-policy-route-map-$route_map-rule-$rule") {
    system "$VTYSH -c \"configure terminal\" -c \"no route-map $route_map $action $rule\"";
}
