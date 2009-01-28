#!/usr/bin/perl -w
#
# Module: vyatta-policy-action-verify.pl
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
# **** End License ****
#
use lib "/opt/vyatta/share/perl5/";
use Vyatta::Config;
use Vyatta::Misc;

use warnings;
use strict;
use POSIX;
use File::Copy;

#solution: put a commit statement in the rule node that does the action test and squirt out delete hook in rule node on a delete.

my $route_map = shift;
my $rule = shift;
my $action = shift;

if (!defined($rule) || !defined($route_map)) {
  exit 1;
}

my $config = new Vyatta::Config;

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
    system "/usr/bin/vyatta-vtysh -c \"configure terminal\" -c \"no route-map $route_map $action $rule\"";
}
