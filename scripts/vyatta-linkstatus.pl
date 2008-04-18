#!/usr/bin/perl -w
#
# Module: vyatta-linkstatus.pl
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
if (open(PID, "< /var/run/vyatta/quagga/watchlink.pid")) {
    my $foo = <PID>;
    system "kill -10 $foo";
    close(PID);
}
