#!/usr/bin/perl -w
#
# Module: vyatta-linkstatus.pl
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

use warnings;
use strict;
use POSIX;
use File::Copy;

my $exclude_file = '/var/linkstatus/exclude';
my $exclude_lck_file = '/var/linkstatus/exclude.lck';
my $action = 0;
my $iface;


foreach my $arg (@ARGV) {
    if (substr($arg, 0, 5) eq "--add") {
	$action = 0;
	next;
    }
    elsif (substr($arg, 0, 5) eq "--del") {
	$action = 1;
	next;
    }
    else {
	#must be interface then...
	$iface = $arg;
    }
}

open FILE, "<$exclude_file"; 
open FILE_LCK, "+>$exclude_lck_file";
my $newline = "";
my @excl;

while (<FILE>) {
    @excl = split ',', $_;
    
    foreach my $elem (@excl)
    {
	if ($elem ne $iface) {
	    if ($newline ne '') {
		$newline = "$newline,$elem";
	    }
	    else {
		$newline = $elem;
	    }
	}
    }
}

close FILE;

#if add new now add to end of list
if ($action==0) {
    if ($newline ne '') {
	$newline = "$newline,$iface";
    }
    else {
	$newline = $iface;
    }
}

print FILE_LCK "$newline";
close FILE_LCK;

copy ($exclude_lck_file,$exclude_file);
unlink($exclude_lck_file);


#finally kick the process
open(PID, "< /var/run/vyatta/quagga/watchlink.pid") || die "could not open '/var/run/vyatta/quagga/watchlink.pid'";
my $foo = <PID>; 
system "kill -10 $foo";
close(PID); 
