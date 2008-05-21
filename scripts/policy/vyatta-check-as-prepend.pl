#!/usr/bin/perl
@as_list = split(' ',$ARGV[0]);
foreach $as (@as_list) {
    if ($as =~ /[^\d\s]/ || $as < 1 || $as > 4294967294) { exit 1;}
}
if (scalar(@as_list) > 24) {
    print "Error: max 24 as paths";
    exit 1;
}
exit 0;
