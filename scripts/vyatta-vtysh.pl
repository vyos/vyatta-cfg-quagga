#!/usr/bin/perl -w
#
# Module: vyatta-vtysh.pl
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
# Portions created by Vyatta are Copyright (C) 2007 Vyatta, Inc.
# All Rights Reserved.
# 
# Author: Stig Thormodsrud
# Date: December 2007
# Description: Wrapper script between vyatta cfg templates and vtysh
# 
# **** End License ****
#

use warnings;
use strict;
use POSIX;

my $vtysh;

if ( -x '/usr/bin/vyatta-vtysh' && -S '/var/run/vyatta/quagga/zebra.vty' ) {
   $vtysh = '/usr/bin/vyatta-vtysh';
} else {
   $vtysh = '/usr/bin/vtysh';
}

my $logfile = '/tmp/vtysh.log';

my $ignore_error = 0;

sub log_it {
    my ($cmdline) = @_;

    if (substr($cmdline,0,2) eq "-c" and $ignore_error) {
	$cmdline = "-n $cmdline";
    }
    my $timestamp = strftime("%Y%m%d-%H:%M.%S", localtime);
    my $user = $ENV{'USER'};
    $user = "boot" if !defined $user;
    my $rc = open(my $fh, ">>", $logfile);
    if (!defined $rc) {
	print "Can't open $logfile: [$!]\n";
	return;
    }
    print $fh "$timestamp:$user [$cmdline]\n";
    close($fh);
}

sub parse_cmdline {
    my $cmdline = "";

    foreach my $arg (@ARGV) {
	if (substr($arg, 0, 2) eq "-n") {
	    $ignore_error = 1;
	    next;
	}
	if (substr($arg,0, 2) eq "-c") {
	    #
	    # This script expects a space between the -c and the command,
	    # but try to handle it anyway
	    #
	    if ($arg ne "-c") {
		my $tmp = substr($arg,2);
		$cmdline .= "-c \"$tmp\" ";
		next;
	    } 
	} else {
	    $arg = " \"$arg\" ";
	}
	$cmdline .= $arg;
    }
    return $cmdline
}

#
# Send the config to quagga
#
# Note: Quagga never exits with an error code, but it does print an
#       error message to stdout.  So if there is output, print it and
#       exit with an error.  Certain error messages we dont' care about
#       such as issuing a "no <foo>" when foo doesn't exist.  In those
#       cases it is up to the template file whether or not to fail on 
#       the error code.
#
sub send_cmds_to_quagga {
    my ($cmdline) = @_;

    my $output = `$vtysh $cmdline`;
    if (defined $output && $output ne "") {
	if ($ignore_error) {
	    log_it("Ignoring: $output");
	    return 0;
	}
	log_it("Error: $output");
	print "%$output\n";
	return 1;
    }
    return 0;
}

sub usage {
    print "usage: $0 [-n] -c \"<quagga command>\"\n";
}

#
# main
#
my ($cmdline, $rc);
$cmdline = parse_cmdline();
log_it($cmdline);
if (! defined($cmdline) or $cmdline eq "") {
    usage();
    exit 1;
}
$rc = send_cmds_to_quagga($cmdline);
exit $rc

#end of file
