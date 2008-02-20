#!/usr/bin/perl -w
#
# Module: vyatta-wanloadbalance.pl
# 
# **** License ****
# Version: VPL 1.0
# 
# The contents of this file are subject to the Vyatta Public License
# Version 1.0 ("License"); you may not use this file except in
# compliance with the License. You may obtain a copy of the License at
# http://www.vyatta.com/vpl
# 
# Software distributed under the License is distributed on an "AS IS"
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
# the License for the specific language governing rights and limitations
# under the License.
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
    system "/opt/vyatta/sbin/vyatta-vtysh.pl -c \"configure terminal\" -c \"no route-map $route_map $action $rule\"";
}
