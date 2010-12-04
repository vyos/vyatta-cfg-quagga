# Author: Robert Bays <robert@vyatta.com>
# Date: 2010
# Description: interface between Vyatta templates and Quagga vtysh

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
# Portions created by Vyatta are Copyright (C) 2010 Vyatta, Inc.
# All Rights Reserved.
# **** End License ****

package Vyatta::Quagga::Config;

use strict;
use warnings;

use lib "/opt/vyatta/share/perl5/";
use Vyatta::Config;

my $_DEBUG = 0;
my %_vtysh;
my %_vtyshdel;
my $_qcomref = '';
my $_vtyshexe = '/usr/bin/vtysh';

###  Public methods -
# Create the class.  
# input: $1 - level of the Vyatta config tree to start at
#        $2 - hash of hashes ref to Quagga set/delete command templates
sub new {
  my $that = shift;
  my $class = ref ($that) || $that;
  my $self = {
    _level  => shift,
    _qcref  => shift,
  };

  $_qcomref = $self->{_qcref};

  if (! _qtree($self->{_level}, 'del')) { return 0; }
  if (! _qtree($self->{_level}, 'set')) { return 0; }

  bless $self, $class;
  return $self;
}

# Set/check debug level 
# input: $1 - debug level
sub setDebugLevel {
  my ($self, $level) = @_;
  if ($level > 0) {
    $_DEBUG = $level; 
    return $level;
  }
  return 0;
}

sub returnDebugLevel {
  return $_DEBUG;
}

# reinitialize the vtysh hashes for troublshooting tree
# walk post object creation
sub _reInitialize {
  my ($self) = @_;

  %_vtysh = ();
  %_vtyshdel = ();
  _qtree($self->{_level}, 'del');
  _qtree($self->{_level}, 'set');
}

# populate an array reference with Quagga commands
sub returnQuaggaCommands {
  my ($self, $arrayref) = @_; 

  foreach my $key (sort { $b cmp $a } keys %_vtyshdel) {
    foreach my $string (@{$_vtyshdel{$key}}) {
      push @{$arrayref}, "$string";
    }
  }

  foreach my $key (sort keys %_vtysh) {
    foreach my $string (@{$_vtysh{$key}}) {
      push @{$arrayref}, "$string";
    }
  }

  return 1;
}

# methods to send the commands to Quagga
sub setConfigTree {
  my ($self, $level, $skip_list, $ordered_list) = @_;
  if (_setConfigTree($level, 0, 0, $skip_list, $ordered_list)) { return 1; }
  return 0;
}

sub setConfigTreeRecursive {
  my ($self, $level, $skip_list, $ordered_list) = @_;
  if (_setConfigTree($level, 0, 1, $skip_list, $ordered_list)) { return 1; }
  return 0;
}

sub deleteConfigTree {
  my ($self, $level, $skip_list, $ordered_list) = @_;
  if (_setConfigTree($level, 1, 0, $skip_list, $ordered_list)) { return 1; }
  return 0;
}

sub deleteConfigTreeRecursive {
  my ($self, $level, $skip_list, $ordered_list) = @_;
  if (_setConfigTree($level, 1, 1, $skip_list, $ordered_list)) { return 1; }
  return 0;
}

### End Public methods -
### Private methods
sub _pdebug {
  my ($level, $msg) = @_;

  if (! defined $level) { return 0; }
  if ($_DEBUG >= $level) { print "DEBUG: $msg\n"; }
  return 1;
}

# traverse the set/delete trees and send commands to quagga
# set traverses from $level in tree top down.  
# delete traverses from bottom up in tree to $level.
# execute commands in tree one at a time.  If there is an error in vtysh,
# fail.  otherwise, remove command from tree on success as we may traverse
# this portion of the tree again otherwise.
# input: $1 - level of the tree to start at
#        $2 - delete bool
#        $3 - recursive bool
#        $4 - arrays of strings to skip 
# output: none, return failure if needed
sub _setConfigTree {
  my ($level, $delete, $recurse, $skip, $ordered) = @_;
  my $qcom = $_qcomref;
  my @com_array = ();
  my @skip_list = ();
  my @ordered_list = ();

  if (defined $skip) { @skip_list = @$skip; }
  if (defined $ordered) { @ordered_list = @$ordered; }

  if ((! defined $level)   ||
      (! defined $delete)  ||
      (! defined $recurse))      { return 0; }

  # default tree is the set vtysh hash
  my $vtyshref = \%_vtysh;
  # default tree walk order is top down
  my $sortfunc = \&cmpf;

  # if this is delete, use delete vtysh hash and walk the tree bottom up
  if ($delete) { 
    $vtyshref = \%_vtyshdel; 
    $sortfunc = \&cmpb;
  }

  _pdebug(3, "_setConfigTree - enter - level: $level\tdelete: $delete\trecurse: $recurse\tskip: @skip_list\tordered_list\t@ordered_list");

  # This loop walks the arrays of quagga commands and builds list to send to quagga
  foreach my $key (keys %$vtyshref) {
    _pdebug(3, "_setConfigTree - key $key");

    # skip parameters listed in skip_list
    my $found = 0;
    if ((scalar @skip_list) > 0) {
      foreach my $node (@skip_list) {
        if ($key =~ /$node/) { 
          $found = 1; 
          _pdebug(3, "_setConfigTree - key $node in skip list"); 
        }
      }
    }
    if ($found) { next; }

    # should we run the vtysh command with noerr?
    my $noerr = '';
    if ( (defined $qcom->{$key}->{'noerr'}) && (
         ($qcom->{$key}->{'noerr'} eq "both") || 
         (($qcom->{$key}->{'noerr'} eq "del") && ($delete)) ||
         (($qcom->{$key}->{'noerr'} eq "set") && (!$delete)))) { $noerr = 1; }

    # this conditional matches key to level exactly or if recurse, start of key to level
    if ((($recurse) && ($key =~ /^$level/)) || ((! $recurse) && ($key =~ /^$level$/))) {
      my $index = 0;
      foreach my $cmd (@{$vtyshref->{$key}}) {
        _pdebug(2, "_setConfigTree - key: $key \t cmd: $cmd");
        
        push @com_array, "$cmd  !!??  $noerr";
        # remove this command so we don't hit it again in another Recurse call
        delete ${$vtyshref->{$key}}[$index];
        $index++;
      }
    }
  }

  # Now let's sort based on ordered_list
  my $index = 0;
  while (scalar @ordered_list > 0) {
    my $prio = shift @ordered_list;
    my $str = sprintf "%5d", $index;
    foreach my $line (@com_array) {
      # add sorting order meta-data to list
      $line =~ s/$prio/$str\:::$prio/;
    }
    $index++;
  }

  # and now send the commands to quagga
  foreach my $line (sort $sortfunc @com_array) {
    my ($order, $command, $noerr);

    # remove the ordered_list sorting meta-data
    $line =~ s/\s+\d+:::/ /;
    # remove the sort order prepend
    ($order, $command) = split /  !!!\?\?\?  /, $line;
    # split for our noeer info
    ($command, $noerr) = split /  !!\?\?  /, $command;
    if (! _sendQuaggaCommand("$command", "$noerr")) { return 0; }
  }

  return 1;
}

# sort subs for _setConfigTree
sub cmpf { $a cmp $b }
sub cmpb { $b cmp $a }

# properly format a Quagga command for vtysh and send to Quagga
# input: $1 - qVarReplaced Quagga Command string
#        $2 - boolean: should we use noerr?
# output: none, return failure if needed
sub _sendQuaggaCommand {
  my ($command, $noerr) = @_;
  
  my @arg_array = ("$_vtyshexe");
  if ($noerr) { push (@arg_array, '--noerr'); }
  if (returnDebugLevel() >= 2) { push (@arg_array, '-E'); }
  push (@arg_array, '-c');
  push (@arg_array, 'configure terminal');

  my @commands = split / ; /, $command;
  foreach my $section (@commands) {
    push (@arg_array, '-c');
    push (@arg_array, "$section");
  }
  
  system(@arg_array) == 0 or _logger(\@arg_array, 1);

  return 1;
}

# log error message to syslog, optionally die
# input: $1 - reference to error message array
#        $2 - die boolean
sub _logger {
  my $error_array = shift;
  my $die = shift;
  my @logger_cmd = ("/usr/bin/logger");

  push (@logger_cmd, "-i");
  push (@logger_cmd, "-t vyatta-cfg-quagga");
  if (returnDebugLevel() > 0) { push (@logger_cmd, "-s"); }
  push (@logger_cmd, "@{$error_array} failed: $?");

  system(@logger_cmd) == 0 or die "unable to log system error message.";

  if ($die) { die "Error configuring routing subsystem.  See log for more detailed information\n"; }
  return 1;
}

# translate a Vyatta config tree into a Quagga command using %qcom as a template.
# input: $1 - Vyatta config tree string
#        $2 - Quagga command template string
# output: Quagga command suitable for vtysh as defined by %qcom.
sub _qVarReplace {
  my $node = shift;
  my $qcommand = shift;

  _pdebug(2, "_qVarReplace entry: node - $node\n_qVarReplace entry: qcommand - $qcommand");

  my @nodes = split /\s/, $node;
  my @qcommands = split /\s/, $qcommand;

  my $result = '';
  # try to replace (#num, ?var) references foreach item in Quagga command template array
  # with their corresponding value in Vyatta command array at (#num) index
  foreach my $token (@qcommands) {
    # is this a #var reference? if so translate and append to result
    if ($token =~ s/\#(\d+);*/$1/) {
      $token--;
      $result="$result $nodes[$token]";
    }
    # is this a ?var reference? if so check for existance of the var in Vyatta Config 
    # tree and conditionally append.  append token + value.  These conditional vars 
    # will only work at EOL in template string.
    elsif ($token =~ s/\?(\w+);*/$1/) {
      # TODO: Vyatta::Config needs to be fixed to accept level in constructor
      my $config = new Vyatta::Config;
      $config->setLevel($node);
      my $value = $config->returnValue($token);
      if ($value) { $result = "$result $token $value"; }
      elsif ($config->exists($token)) { $result = "$result $token"; }
    }
    # is this a @var reference? if so, append just the value instead of token + value
    elsif ($token =~ s/\@(\w+);*/$1/) {
      my $config = new Vyatta::Config;
      $config->setLevel($node);
      my $value = $config->returnValue($token);
      if (defined $value) { $result = "$result $value"; }
    }
    # if not, just append string to result
    else {
      $result = "$result $token";
    }
  }

  # remove leading space characters
  $result =~ s/^\s(.+)/$1/;
  _pdebug(2, "_qVarReplace exit: result - $result");

  return $result;
}

# For given Vyatta config tree string, find a corresponding Quagga command template 
# string as defined in %qcom
# input: $1 - Vyatta config tree string
#        $2 - action (set|del)
#        $3 - Quagga command template hash
# output: %qcom hash key to corresponding Quagga command template string
sub _qCommandFind {
  my $vyattaconfig = shift;
  my $action = shift;
  my $qcom = shift;
  my $command = '';

  my @nodes = split /\s+/, $vyattaconfig;

  # append each token in the Vyatta config tree.  sequentially  
  # check if there is a corresponding hash in %qcom.  if not,
  # do same check again replacing the end param with var to see
  # if this is a var replacement
  foreach my $token (@nodes) {
    if    (exists $qcom->{$token}->{$action})            { $command = $token; }
    elsif (exists $qcom->{"$command $token"}->{$action}) { $command = "$command $token"; }
    elsif (exists $qcom->{"$command var"}->{$action})    { $command = "$command var"; }
    else { return undef; }
  }

  # return hash key if Quagga command template string is found
  if (defined $qcom->{$command}->{$action}) { return $command; }
  else { return undef; }
}

# translate the adds/changes in a Vyatta config tree into Quagga vtysh commands.
# recursively walks the tree.  
# input:  $1 - the level of the Vyatta config tree to start at
#         $2 - the action (set|delete)
# output: none - creates the %vtysh that contains the Quagga add commands
sub _qtree {
  my ($level, $action) = @_;
  my @nodes;
  my ($qcom, $vtysh);

  $qcom = $_qcomref;
  
  # Would love to reference a global config and just reset Levels,
  # but Vyatta::Config isn't recursion safe.
  my $config = new Vyatta::Config;
  $config->setLevel($level);

  # setup references for set or delete action
  if ($action eq 'set') {
    $vtysh = \%_vtysh;
    @nodes = $config->listNodes();
  }
  else {
    $vtysh = \%_vtyshdel;
    @nodes = $config->listDeleted();

    # handle special case for multi-nodes values being deleted
    # listDeleted() doesn't return the node as deleted if it is a multi
    # unless all values are deleted.
    # TODO: fix listDeleted() in Config.pm
    # This is really, really fugly.
    my @all_nodes = $config->listNodes();
    foreach my $node (@all_nodes) {
      my @array = split /\s+/, $level;
      push @array, $node;
      my ($multi, $text, $default) = $config->parseTmpl(\@array);
      if ($multi) {
        my @orig_values = $config->returnOrigValues("$node");
        my @new_values = $config->returnValues("$node");
        my %chash = $config->compareValueLists(\@orig_values, \@new_values);
        if (${$chash{'deleted'}}[0]) {                 
          push @nodes, $node;
        }
      }
    }

  } ## end else {

  _pdebug(1, "_qtree - action: $action\tlevel: $level");

  # traverse the Vyatta config tree and translate to Quagga commands where apropos
  if (@nodes > 0) {
    foreach my $node (@nodes) {
      _pdebug(2, "_qtree - foreach node loop - node $node");

      # for set action, need to check that the node was actually changed.  Otherwise
      # we end up re-writing every node to Quagga every commit, which is bad. Mmm' ok?
      if (($action eq 'del') || ($config->isChanged("$node"))) {
        # is there a Quagga command template?
        # TODO: need to add function reference support to qcom hash for complicated nodes
        my $qcommand = _qCommandFind("$level $node", $action, $qcom);

        # if I found a Quagga command template, then replace any vars
        if ($qcommand) {
          # get the apropos config value so we can use it in the Quagga command template
          my @vals = undef;

          # This is either a set or delete on a single or multi: node
          if ($action eq 'set') {
            my $tmplhash = $config->parseTmplAll($node);
            if ($tmplhash->{'multi'}) {
              _pdebug(2, "multi");
              @vals = $config->returnValues($node);
            }
            else {
              _pdebug(2, "not a multi");
              $vals[0] = $config->returnValue($node);
            }
          }
          else {
            my $tmplhash = $config->parseTmplAll($node);
            if ($tmplhash->{'multi'}) {
              _pdebug(2, "multi"); 
              @vals = $config->returnOrigValues($node);
            }
            else {
              _pdebug(2, "not a multi");
              $vals[0] = $config->returnOrigValue($node);
            }
          }

          # is this a leaf node?
          if (defined $vals[0]) {
            foreach my $val (@vals) {
              my $var = _qVarReplace("$level $node $val", $qcom->{$qcommand}->{$action});
              push @{$vtysh->{"$qcommand"}}, "$level $node $val  !!!???  $var";
              _pdebug(1, "_qtree leaf node command: set $level $action $node $val \n\t\t\t\t\t$var");
            }
          }

          else {
            my $var = _qVarReplace("$level $node", $qcom->{$qcommand}->{$action});
            push @{$vtysh->{"$qcommand"}}, "$level $node  !!!???  $var";
            _pdebug(1, "_qtree node command: set $level $action $node \n\t\t\t\t$var");
          }
        }
      }
      # recurse to next level in tree
      _qtree("$level $node", 'del');
      _qtree("$level $node", 'set');
    }
  }

  return 1;
}

return 1;
