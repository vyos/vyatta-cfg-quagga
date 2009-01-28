#! /usr/bin/perl
#
# Script used to restore protocol configuration

use strict;
use lib "/opt/vyatta/share/perl5";
use Vyatta::ConfigOutput;
use Vyatta::ConfigLoad;

my $sbindir           = $ENV{vyatta_sbindir};
my $cfg               = 'vyatta-cfg-cmd-wrapper';
my $active_config_dir = "/opt/vyatta/config/active";

sub usage {
    die "Usage: $0 protocol\n", "protocol := bgp|ospf|rip|ripng\n";
}

sub save_config {
    my $file        = shift;
    my $version_str = `/opt/vyatta/sbin/vyatta_current_conf_ver.pl`;
    die "no version string??" unless $version_str;

    open my $save, '+>', $file
      or die "Can not open file '$file': $!\n";

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

sub config {
    my @args = @_;
    push @args, $cfg;
    print join( ' ', @args ), "\n";
    return system "$sbindir/$cfg", @args == 0;
}

sub cleanup {
    config('cleanup');
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
        my @cmd = @{$cmd_ref};

        warn "Set failed: ", join(' '), @cmd
          unless config( 'set', @{$cmd_ref} );
    }

    die "Commit failed"
      unless config('commit');
}

my %protomap = (
    'bgp'  => ['protocols/bpp'],
    'ospf' => [ 'protocols/ospf', 'interfaces/*/*/ip/ospf' ],
    'rip'  => [ 'protocols/rip', 'interfaces/*/*/ip/rip' ],
);

my $proto = shift @ARGV;
usage unless $proto;

my @nodes = $protomap{$proto};
usage unless @nodes;

$SIG{__DIE__} = \&cleanup;
$SIG{TERM}    = \&cleanup;

# Step 0: lock out any new transactions
config('begin');

# Step 1: save current configuration
my $save_file = "/tmp/$0-$proto.$$";
my $save      = save_config($save_file);

# Step 2: remove old state
clean_nodes(@nodes);

# Step 3: reload
seek $save, 0, 0;
load_config($save);

config('end');

close $save;
## unlink $save_file;

