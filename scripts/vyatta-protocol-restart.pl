#! /usr/bin/perl
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
# A copy of the GNU General Public License is available as
# `/usr/share/common-licenses/GPL' in the Debian GNU/Linux distribution
# or on the World Wide Web at `http://www.gnu.org/copyleft/gpl.html'.
# You can also obtain it by writing to the Free Software Foundation,
# Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# This code was originally developed by Vyatta, Inc.
# Portions created by Vyatta are Copyright (C) 2008 Vyatta, Inc.
# All Rights Reserved.
# **** End License ****
#
# Author: Stephen Hemminger
# Date: January 2009
# Description: Script used to restore protocol configuration on quagga daemon
# restart
#
# Not meant to be run directly, it is wrapped inside another script
# that sets up transaction

use strict;
use warnings;
use lib "/opt/vyatta/share/perl5/";
use Vyatta::ConfigOutput;
use Vyatta::ConfigLoad;

my $sbindir           = '/opt/vyatta/sbin';
my $active_config_dir = "/opt/vyatta/config/active";

my %protomap = (
    'bgp'  => ['protocols/bpp'],
    'ospf' => [ 'protocols/ospf', 'interfaces/*/*/ip/ospf' ],
    'rip'  => [ 'protocols/rip', 'interfaces/*/*/ip/rip' ],
);

sub usage {
    die "Usage: $0 {",join('|',keys %protomap),"}\n";
}

sub save_config {
    my $file        = shift;
    my $version_str = `/opt/vyatta/sbin/vyatta_current_conf_ver.pl`;
    die "no version string??" unless $version_str;

    open my $save, '+>', $file
	or return; #undef

    select $save;
    set_show_all(1);
    outputActiveConfig();
    print $version_str;
    select STDOUT;
    print "created $file\n";

    return $save;
}

sub clean_nodes {
    foreach my $path (@_) {
        system("rm -rf $active_config_dir/$path");
    }
}

sub load_config {
    my $file     = shift;
    my %cfg_hier = Vyatta::ConfigLoad::loadConfigHierarchy($file);
    die "Saved configuration was bad can't reload"
      unless %cfg_hier;

    my %cfg_diff = Vyatta::ConfigLoad::getConfigDiff( \%cfg_hier );

    # Only doing sets
    foreach ( @{ $cfg_diff{'set'} } ) {
        my ( $cmd_ref, $rank ) = @{$_};
        my @cmd = ( "my_set", @{$cmd_ref} );
	
	system "$sbindir/my_set", @cmd == 0
	    or warn join(' '), @cmd;
    }
}


my $proto = shift @ARGV;
usage unless $proto;

my @nodes = $protomap{$proto};
usage unless @nodes;

# set up the config environment
my $CWRAPPER = '/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper';
system ("$CWRAPPER begin") == 0
    or die "Cannot set up configuration environment\n";

# Step 1: save current configuration
my $save_file = "/tmp/$0-$proto.$$";
my $save      = save_config($save_file);
if (! defined $save) {
    system "$CWRAPPER cleanup";
    die "Can not open file '$save_file': $!\n";
}

# Step 2: remove old state
clean_nodes(@nodes);

# Step 3: reload
seek $save, 0, 0;
load_config($save);
close $save;

# Step 4: finalize
system "$CWRAPPER commit" == 0
    or die "Reload failed: check $save_file\n";

unlink $save_file;

