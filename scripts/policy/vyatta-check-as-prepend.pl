#!/usr/bin/perl
use strict;

my @as_list = split( ' ', $ARGV[0] );
foreach my $as (@as_list) {
    exit 1 if ( $as =~ /[^\d\s]/ || $as < 1 || $as > 4294967294 );
}

die "Error: max 24 as path\n" if ( scalar(@as_list) > 24 );

exit 0;
