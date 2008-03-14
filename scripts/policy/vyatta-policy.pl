#!/usr/bin/perl
use lib "/opt/vyatta/share/perl5/";
use VyattaConfig;
use VyattaMisc;
use Getopt::Long;
$VTYSH='/opt/vyatta/sbin/vyatta-vtysh.pl';

GetOptions("update-access-list=s"    => \$accesslist,
           "update-aspath-list=s"    => \$aspathlist,
           "update-community-list=s" => \$communitylist,
           "check-peer-syntax=s"     => \$peer,
           "check-routemap-action=s" => \$routemap,
           "check-delete-routemap-action=s" => \$deleteroutemap,
);

if (defined $accesslist)    { update_access_list($accesslist); }
if (defined $aspathlist)    { update_as_path($aspathlist); }
if (defined $communitylist) { update_community_list($communitylist); }
if (defined $peer)          { check_peer_syntax($peer); }
if (defined $routemap)      { check_routemap_action($routemap); }
if (defined $deleteroutemap) { check_delete_routemap_action($deleteroutemap); }

exit 0;

sub numerically { $a <=> $b; }

sub check_peer_syntax() {
  my $peer = shift;
  
  $_ = $peer;
  if (/^local$/) { exit 0; }
  if (isIpAddress("$peer")) { exit 0; }
  exit 1;
}

sub is_community_list {
    my $list = shift;

    my $count = `$VTYSH -c \"show ip community-list $list\" | grep $list | wc -l`;
    if ($count > 0) {
	return 1; 
    } else {
	return 0;
    }
}

sub update_community_list() {
  my $num = shift;
  my $config = new VyattaConfig;
  my @rules = ();
  my $rule;

  # remove the old rule
  if (is_community_list($num)) {
      system("$VTYSH -c \"configure terminal\" -c \"no ip community-list $num\" ");
  }

  $config->setLevel("policy community-list $num rule");
  @rules = $config->listNodes();

  foreach $rule (sort numerically @rules) {
    my $action, $regex = '';

    # set the action
    $action = $config->returnValue("$rule action");
    if (! defined $action) {
      print "You must specify an action for as-path-list $list rule $rule\n";
      exit 1;
    }

    # grab the regex
    if (defined $config->returnValue("$rule regex")) {
      $regex = $config->returnValue("$rule regex");
    }
    else {
      print "You must specify a regex for community-list $list rule $rule\n";
      exit 1;
    }

   system ("$VTYSH -c \"configure terminal\" -c \"ip community-list $num $action $regex\" ");
  }

  exit 0;
}

sub is_as_path_list {
    my $list = shift;

    my $count = `$VTYSH -c \"show ip as-path-access-list $list\" | grep $list | wc -l`;
    if ($count > 0) {
	return 1; 
    } else {
	return 0;
    }
}

sub update_as_path() {
  my $word = shift;
  my $config = new VyattaConfig;
  my @rules = ();
  my $rule;

  # remove the old rule
  if (is_as_path_list($word)) {
      system("$VTYSH -c \"configure terminal\" -c \"no ip as-path access-list $word\" ");
  }

  $config->setLevel("policy as-path-list $word rule");
  @rules = $config->listNodes();

  foreach $rule (sort numerically @rules) {
    my $action, $regex = '';

    # set the action
    $action = $config->returnValue("$rule action");
    if (! defined $action) {
      print "You must specify an action for as-path-list $list rule $rule\n";
      exit 1;
    }

    # grab the regex
    if (defined $config->returnValue("$rule regex")) {
      $regex = $config->returnValue("$rule regex");
    }
    else {
      print "You must specify a regex for as-path-list $list rule $rule\n";
      exit 1;
    }

   system ("$VTYSH -c \"configure terminal\" -c \"ip as-path access-list $word $action $regex\" ");
  }

  exit 0;
}

sub is_access_list {
    my $list = shift;

    my $count = `$VTYSH -c \"show ip access-list $list\" | grep $list | wc -l`;
    if ($count > 0) {
	return 1; 
    } else {
	return 0;
    }
}

sub update_access_list() {
  my $list = shift;
  my $config = new VyattaConfig;
  my @rules = ();
  my $rule;

  # remove the old rule if it already exists
  if (is_access_list($list)) {
      system ("$VTYSH -c \"configure terminal\" -c \"no access-list $list\" ");
  }

  $config->setLevel("policy access-list $list rule");
  @rules = $config->listNodes();

  foreach $rule (sort numerically @rules) {
    my $ip, $action, $src, $dst, $srcmsk, $dstmsk = '';

    # set the action
    $action = $config->returnValue("$rule action");
    if (! defined $action) { 
      print "You must specify an action for access-list $list rule $rule\n";
      exit 1;
    }

    # TODO: ask someone why config->exists() is returning !0?
    # set the source filter
    if (defined $config->returnValue("$rule source host")) { 
      $src = $config->returnValue("$rule source host"); 
      $src = "host " . $src;
    }
    elsif (defined $config->returnValue("$rule source network")) { 
      $src  = $config->returnValue("$rule source network"); 
      $srcmsk = $config->returnValue("$rule source inverse-mask"); 
    }
    else {
      if ($config->exists("$rule source any")) { $src = "any"; }
      else {
        print "error in source section of access-list $list rule $rule\n";
        exit 1;
      }
    }

    # set the destination filter if extended list
    if ((($list >= 100) && ($list <= 199)) || (($list >= 2000) && ($list <= 2699))) {
      $ip = 'ip ';
      # TODO: ask someone why config->exists() is returning !0?
      if (defined $config->returnValue("$rule destination host")) { 
        $dst = $config->returnValue("$rule destination host"); 
        $dst = "host " . $dst;
      }
      elsif (defined $config->returnValue("$rule destination network")) {
        $dst  = $config->returnValue("$rule destination network");
        $dstmsk = $config->returnValue("$rule destination inverse-mask");
      }
      else {
        if ($config->exists("$rule destination any")) { $dst = "any"; }
        else {
          print "error in destination section of access-list $list rule $rule\n";
          exit 1;
        }
      }
    }

   system ("$VTYSH -c \"configure terminal\" -c \"access-list $list $action $ip $src $srcmsk $dst $dstmsk\" "); 
  }

  exit 0; 
}

## check_routemap_action
# check if the action has been changed since the last commit.
# we need to do this because quagga will wipe the entire config if
# the action is changed.
# $1 = policy route-map <name> rule <num> action
sub check_routemap_action() {
  my $routemap = shift;
  my $config = new VyattaConfig;

  my $action = $config->setLevel("$routemap");
  my $origvalue = $config->returnOrigValue();
  if ($origvalue) {
    my $value = $config->returnValue();
    if ("$value" ne "$origvalue") {
      exit 1;
    }
  }

  exit 0;
}

## check_delete_routemap_action
# don't allow deleteing the route-map action if other sibling nodes exist.
# action is required for all other route-map definitions
# $1 = policy route-map <name> rule <num>
sub check_delete_routemap_action() {
  my $routemap = shift;
  my $config = new VyattaConfig;

  my @nodes = $config->listNodes("$routemap");
  if (defined @nodes) {
    exit 1
  }

  exit 0;
}
