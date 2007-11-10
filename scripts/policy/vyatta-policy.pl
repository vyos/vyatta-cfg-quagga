#!/usr/bin/perl
use lib "/opt/vyatta/share/perl5/";
use VyattaConfig;
use VyattaMisc;
use Getopt::Long;
$VTYSH='/usr/bin/vtysh';

GetOptions("update-access-list=s"    => \$accesslist,
           "update-aspath-list=s"    => \$aspathlist,
           "update-community-list=s" => \$communitylist,
           "check-peer-syntax=s"     => \$peer,
);

if (defined $accesslist)    { update_access_list($accesslist); }
if (defined $aspathlist)    { update_as_path($aspathlist); }
if (defined $communitylist) { update_community_list($communitylist); }
if (defined $peer)          { check_peer_syntax($peer); }

exit 0;

sub numerically { $a <=> $b; }

sub check_peer_syntax() {
  my $peer = shift;
  
  $_ = $peer;
  if (/^local$/) { exit 0; }
  if (isIpAddress("$peer")) { exit 0; }
  exit 1;
}

sub update_community_list() {
  my $num = shift;
  my $config = new VyattaConfig;
  my @rules = ();
  my $rule;

  # remove the old rule
  system ("$VTYSH -c \"configure terminal\" -c \"no ip community-list $num\" ");

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

sub update_as_path() {
  my $word = shift;
  my $config = new VyattaConfig;
  my @rules = ();
  my $rule;

  # remove the old rule
  system ("$VTYSH -c \"configure terminal\" -c \"no ip as-path access-list $word\" ");

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

sub update_access_list() {
  my $list = shift;
  my $config = new VyattaConfig;
  my @rules = ();
  my $rule;

  # remove the old rule
  system ("$VTYSH -c \"configure terminal\" -c \"no access-list $list\" ");

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
      $src = $config->returnValue("$rule source any");
      if ("$src" eq "true") { $src = "any"; }
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
        $dst = $config->returnValue("$rule destination any");
        if ("$dst" eq "true") { $dst = "any"; }
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

