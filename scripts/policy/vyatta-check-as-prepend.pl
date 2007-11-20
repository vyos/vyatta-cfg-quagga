#!/usr/bin/perl
@as_list = split(' ',$ARGV[0]);
foreach $as (@as_list) {
    if ($as =~ /[^\d\s]/ || $as < 1 || $as > 65535) { exit 1;}
}
exit 0;
