#!/usr/bin/perl
# Module: vyatta-gateway-static_route-check.pl 
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
#
# Author: Mohit Mehta
# Date: June 2008
# Description: Script to check if any one of the 'static route' is equivalent to the 'system gateway-address'
#              if yes, then don't remove route from routing table unless both are unset
# **** End License ****

use strict;
use warnings;
use lib "/opt/vyatta/share/perl5/";

use NetAddr::IP;
use VyattaConfig;


if (($#ARGV == 1) && ($ARGV[0] eq '0.0.0.0/0')) {
    # check when deleting static-route
    my $vcCHECK_GATEWAY = new VyattaConfig();
    $vcCHECK_GATEWAY->setLevel('system');
    if ( $vcCHECK_GATEWAY->exists('.') ) {
     my $gateway_ip = $vcCHECK_GATEWAY->returnValue('gateway-address');
     if ( defined($gateway_ip) && $gateway_ip eq $ARGV[1] ) {
        exit 1;
     }
    }
    
} elsif ($#ARGV == 0) {
    # check when deleting gateway-address                
    my $vcCHECK_STATIC_ROUTE = new VyattaConfig();
    $vcCHECK_STATIC_ROUTE->setLevel('protocols static');
    if ( $vcCHECK_STATIC_ROUTE->exists('.') ) {
     my @routes = $vcCHECK_STATIC_ROUTE->listNodes("route");
     if (@routes > 0) {
      foreach my $route (@routes) {
       if ($route eq '0.0.0.0/0') {
         my @next_hops = $vcCHECK_STATIC_ROUTE->listNodes("route $route next-hop");
          foreach my $next_hop (@next_hops) {
           if ($next_hop eq $ARGV[0]) {
            exit 1;
           }
          }
       }
      } 
     }
    }
}
 
exit 0;    
