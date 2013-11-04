#!/usr/bin/perl
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
# Portions created by Vyatta are Copyright (C) 2009,2010 Vyatta, Inc.
# All Rights Reserved.
#
# Author: Various
# Date: 2009-2010
# Description: Script to setup Quagga BGP configuration
#
# **** End License ****
#

use strict;
use warnings;

use Getopt::Long;
use NetAddr::IP::Lite;

use lib "/opt/vyatta/share/perl5/";
use Vyatta::Config;
use Vyatta::Quagga::Config;
use Vyatta::Misc;

my %qcom = (
  'protocols' => {
      set => undef,
      del => undef,
  },
  'protocols bgp' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var' => {
      set => 'router bgp #3',
      del => 'no router bgp #3',
  },
  'protocols bgp var address-family' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var address-family ipv6-unicast' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var address-family ipv6-unicast aggregate-address' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var address-family ipv6-unicast aggregate-address var' => {
      set => 'router bgp #3 ; address-family ipv6 ; aggregate-address #7 ?summary-only',
      del => 'router bgp #3 ; address-family ipv6 ; no aggregate-address #7',
  },
  'protocols bgp var address-family ipv6-unicast network' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var address-family ipv6-unicast network var' => {
      set => 'router bgp #3 ; address-family ipv6 ; network #7',
      del => 'router bgp #3 ; address-family ipv6 ; no network #7',
  },
  'protocols bgp var address-family ipv6-unicast network var route-map' => {
      set => 'router bgp #3 ; address-family ipv6 ; network #7 route-map #9',
      del => 'router bgp #3 ; address-family ipv6 ; no network #7 route-map #9',
  },
  'protocols bgp var address-family ipv6-unicast network var path-limit' => {
      set => 'router bgp #3 ; address-family ipv6 ; network #7 pathlimit #9',
      del => 'router bgp #3 ; address-family ipv6 ; no network #7 pathlimit #9',
  },
  'protocols bgp var address-family ipv6-unicast redistribute' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var address-family ipv6-unicast redistribute connected' => {
      set => 'router bgp #3 ; address-family ipv6 ; redistribute connected', 
      del => 'router bgp #3 ; address-family ipv6 ; no redistribute connected',
      noerr => 'set',
  },
  'protocols bgp var address-family ipv6-unicast redistribute connected metric' => {
      set => 'router bgp #3 ; address-family ipv6 ; redistribute connected metric #9', 
      del => 'router bgp #3 ; address-family ipv6 ; no redistribute connected metric #9',
      noerr => 'set',
  },
  'protocols bgp var address-family ipv6-unicast redistribute connected route-map' => {
      set => 'router bgp #3 ; address-family ipv6 ; redistribute connected route-map #9', 
      del => 'router bgp #3 ; address-family ipv6 ; no redistribute connected route-map #9',
      noerr => 'set',
  },
  'protocols bgp var address-family ipv6-unicast redistribute kernel' => {
      set => 'router bgp #3 ; address-family ipv6 ; no redistribute kernel ; redistribute kernel ?route-map ?metric',
      del => 'router bgp #3 ; address-family ipv6 ; no redistribute kernel',
      noerr => 'set',
  },
  'protocols bgp var address-family ipv6-unicast redistribute ospfv3' => {
      set => 'router bgp #3 ; address-family ipv6 ; no redistribute ospf6 ; redistribute ospf6 ?route-map ?metric',
      del => 'router bgp #3 ; address-family ipv6 ; no redistribute ospf6',
      noerr => 'set',
  },
  'protocols bgp var address-family ipv6-unicast redistribute ripng' => {
      set => 'router bgp #3 ; address-family ipv6 ; no redistribute ripng ; redistribute ripng ?route-map ?metric',
      del => 'router bgp #3 ; address-family ipv6 ; no redistribute ripng',
      noerr => 'set',
  },
  'protocols bgp var address-family ipv6-unicast redistribute static' => {
      set => 'router bgp #3 ; address-family ipv6 ; no redistribute static ; redistribute static ?route-map ?metric',
      del => 'router bgp #3 ; address-family ipv6 ; no redistribute static',
      noerr => 'set',
  },
  'protocols bgp var aggregate-address' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var aggregate-address var' => {
      set => 'router bgp #3 ; aggregate-address #5 ?as-set ?summary-only',
      del => 'router bgp #3 ; no aggregate-address #5 ?as-set ?summary-only',
  },
  'protocols bgp var maximum-paths' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var maximum-paths ebgp' => {
      set => 'router bgp #3 ; maximum-paths #6',
      del => 'router bgp #3 ; no maximum-paths #6',
  },
  'protocols bgp var maximum-paths ibgp' => {
      set => 'router bgp #3 ; maximum-paths ibgp #6',
      del => 'router bgp #3 ; no maximum-paths ibgp #6',
  },
  'protocols bgp var neighbor' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var' => {
      set => undef,
      del => 'router bgp #3 ; no neighbor #5',
  },
  'protocols bgp var neighbor var address-family' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var address-family ipv6-unicast' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 activate',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast allowas-in' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 allowas-in',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 allowas-in',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast allowas-in number' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 allowas-in #10',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 allowas-in ; neighbor #5 allowas-in',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast attribute-unchanged' => {
      set => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 attribute-unchanged ; neighbor #5 attribute-unchanged ?as-path ?med ?next-hop',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 attribute-unchanged',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast capability' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var address-family ipv6-unicast capability dynamic' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 capability dynamic',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 capability dynamic',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast capability orf' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var address-family ipv6-unicast capability orf prefix-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var address-family ipv6-unicast capability orf prefix-list receive' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 capability orf prefix-list receive',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 capability orf prefix-list receive',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast capability orf prefix-list send' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 capability orf prefix-list send',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 capability orf prefix-list send',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast default-originate' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 default-originate',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 default-originate',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast default-originate route-map' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 default-originate route-map #10',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 default-originate route-map #10',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast disable-send-community' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var address-family ipv6-unicast disable-send-community extended' => {
      set => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 send-community extended',
      del => 'router bgp #3 ; address-family ipv6 ; neighbor #5 send-community extended',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast disable-send-community standard' => {
      set => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 send-community standard',
      del => 'router bgp #3 ; address-family ipv6 ; neighbor #5 send-community standard',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast distribute-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var address-family ipv6-unicast distribute-list export' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 distribute-list #10 out',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 distribute-list #10 out',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast distribute-list import' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 distribute-list #10 in',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 distribute-list #10 in',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast filter-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var address-family ipv6-unicast filter-list export' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 filter-list #10 out',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 filter-list #10 out',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast filter-list import' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 filter-list #10 in',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 filter-list #10 in',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast maximum-prefix' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 maximum-prefix #9',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 maximum-prefix #9',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast nexthop-local' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 nexthop-local unchanged',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 nexthop-local unchanged',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast nexthop-self' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 next-hop-self',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 next-hop-self',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast peer-group' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 peer-group #9',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 peer-group #9 ; neighbor #5 activate',
      noerr => 'del',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast prefix-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var address-family ipv6-unicast prefix-list export' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 prefix-list #10 out',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 prefix-list #10 out',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast prefix-list import' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 prefix-list #10 in',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 prefix-list #10 in',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast remove-private-as' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 remove-private-AS',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 remove-private-AS',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast route-map' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var address-family ipv6-unicast route-map export' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 route-map #10 out',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 route-map #10 out',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast route-map import' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 route-map #10 in',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 route-map #10 in',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast route-reflector-client' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 route-reflector-client',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 route-reflector-client',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast route-server-client' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 route-server-client',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 route-server-client',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast soft-reconfiguration' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var address-family ipv6-unicast soft-reconfiguration inbound' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 soft-reconfiguration inbound',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 soft-reconfiguration inbound',
  },
  'protocols bgp var neighbor var address-family ipv6-unicast unsuppress-map' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 unsuppress-map #9',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 unsuppress-map #9',
  },
  'protocols bgp var neighbor var advertisement-interval' => {
      set => 'router bgp #3 ; neighbor #5 advertisement-interval #7',
      del => 'router bgp #3 ; no neighbor #5 advertisement-interval',
  },
  'protocols bgp var neighbor var allowas-in' => {
      set => 'router bgp #3 ; neighbor #5 allowas-in',
      del => 'router bgp #3 ; no neighbor #5 allowas-in',
  },
  'protocols bgp var neighbor var allowas-in number' => {
      set => 'router bgp #3 ; neighbor #5 allowas-in #8',
      del => 'router bgp #3 ; no neighbor #5 allowas-in ; neighbor #5 allowas-in',
  },
  'protocols bgp var neighbor var attribute-unchanged' => {
      set => 'router bgp #3 ; no neighbor #5 attribute-unchanged ; neighbor #5 attribute-unchanged ?as-path ?med ?next-hop',
      del => 'router bgp #3 ; no neighbor #5 attribute-unchanged ?as-path ?med ?next-hop',
  },
  'protocols bgp var neighbor var capability' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var capability dynamic' => {
      set => 'router bgp #3 ; neighbor #5 capability dynamic',
      del => 'router bgp #3 ; no neighbor #5 capability dynamic',
  },
  'protocols bgp var neighbor var capability orf' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var capability orf prefix-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var capability orf prefix-list receive' => {
      set => 'router bgp #3 ; neighbor #5 capability orf prefix-list receive',
      del => 'router bgp #3 ; no neighbor #5 capability orf prefix-list receive',
  },
  'protocols bgp var neighbor var capability orf prefix-list send' => {
      set => 'router bgp #3 ; neighbor #5 capability orf prefix-list send',
      del => 'router bgp #3 ; no neighbor #5 capability orf prefix-list send',
  },
  'protocols bgp var neighbor var default-originate' => {
      set => 'router bgp #3 ; neighbor #5 default-originate',
      del => 'router bgp #3 ; no neighbor #5 default-originate',
  },
  'protocols bgp var neighbor var default-originate route-map' => {
      set => 'router bgp #3 ; neighbor #5 default-originate route-map #8',
      del => 'router bgp #3 ; no neighbor #5 default-originate route-map #8',
  },
  'protocols bgp var neighbor var disable-capability-negotiation' => {
      set => 'router bgp #3 ; neighbor #5 dont-capability-negotiate',
      del => 'router bgp #3 ; no neighbor #5 dont-capability-negotiate',
  },
  'protocols bgp var neighbor var disable-connected-check' => {
      set => 'router bgp #3 ; neighbor #5 disable-connected-check',
      del => 'router bgp #3 ; no neighbor #5 disable-connected-check',
  },
  'protocols bgp var neighbor var disable-send-community' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var disable-send-community extended' => {
      set => 'router bgp #3 ; no neighbor #5 send-community extended',
      del => 'router bgp #3 ; neighbor #5 send-community extended',
  },
  'protocols bgp var neighbor var disable-send-community standard' => {
      set => 'router bgp #3 ; no neighbor #5 send-community standard',
      del => 'router bgp #3 ; neighbor #5 send-community standard',
  },
  'protocols bgp var neighbor var distribute-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var distribute-list export' => {
      set => 'router bgp #3 ; neighbor #5 distribute-list #8 out',
      del => 'router bgp #3 ; no neighbor #5 distribute-list #8 out',
  },
  'protocols bgp var neighbor var distribute-list import' => {
      set => 'router bgp #3 ; neighbor #5 distribute-list #8 in',
      del => 'router bgp #3 ; no neighbor #5 distribute-list #8 in',
  },
  'protocols bgp var neighbor var ebgp-multihop' => {
      set => 'router bgp #3 ; neighbor #5 ebgp-multihop #7',
      del => 'router bgp #3 ; no neighbor #5 ebgp-multihop',
  },
  'protocols bgp var neighbor var filter-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var filter-list export' => {
      set => 'router bgp #3 ; neighbor #5 filter-list #8 out',
      del => 'router bgp #3 ; no neighbor #5 filter-list #8 out',
  },
  'protocols bgp var neighbor var filter-list import' => {
      set => 'router bgp #3 ; neighbor #5 filter-list #8 in',
      del => 'router bgp #3 ; no neighbor #5 filter-list #8 in',
  },
  'protocols bgp var neighbor var local-as' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var local-as var' => {
      set => 'router bgp #3 ; no neighbor #5 local-as #7 ; neighbor #5 local-as #7',
      del => 'router bgp #3 ; no neighbor #5 local-as',
  },
  'protocols bgp var neighbor var local-as var no-prepend' => {
      set => 'router bgp #3 ; no neighbor #5 local-as #7 ; neighbor #5 local-as #7 no-prepend',
      del => 'router bgp #3 ; no neighbor #5 local-as #7 no-prepend ; neighbor #5 local-as #7',
  },
  'protocols bgp var neighbor var maximum-prefix' => {
      set => 'router bgp #3 ; neighbor #5 maximum-prefix #7',
      del => 'router bgp #3 ; no neighbor #5 maximum-prefix',
  },
  'protocols bgp var neighbor var nexthop-self' => {
      set => 'router bgp #3 ; neighbor #5 next-hop-self',
      del => 'router bgp #3 ; no neighbor #5 next-hop-self',
  },
  'protocols bgp var neighbor var override-capability' => {
      set => 'router bgp #3 ; neighbor #5 override-capability',
      del => 'router bgp #3 ; no neighbor #5 override-capability',
  },
  'protocols bgp var neighbor var passive' => {
      set => 'router bgp #3 ; neighbor #5 passive',
      del => 'router bgp #3 ; no neighbor #5 passive',
  },
  'protocols bgp var neighbor var password' => {
      set => 'router bgp #3 ; neighbor #5 password #7',
      del => 'router bgp #3 ; no neighbor #5 password',
  },
  'protocols bgp var neighbor var peer-group' => {
      set => 'router bgp #3 ; neighbor #5 peer-group #7',
      del => 'router bgp #3 ; no neighbor #5 peer-group #7 ; neighbor #5 activate',
      noerr => 'del',
  },
  'protocols bgp var neighbor var port' => {
      set => 'router bgp #3 ; neighbor #5 port #7',
      del => 'router bgp #3 ; no neighbor #5 port',
  },
  'protocols bgp var neighbor var prefix-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var prefix-list export' => {
      set => 'router bgp #3 ; neighbor #5 prefix-list #8 out',
      del => 'router bgp #3 ; no neighbor #5 prefix-list #8 out',
  },
  'protocols bgp var neighbor var prefix-list import' => {
      set => 'router bgp #3 ; neighbor #5 prefix-list #8 in',
      del => 'router bgp #3 ; no neighbor #5 prefix-list #8 in',
  },
  'protocols bgp var neighbor var remote-as' => {
      set => 'router bgp #3 ; neighbor #5 remote-as #7 ; neighbor #5 activate',
      del => 'router bgp #3 ; no neighbor #5 remote-as #7',
  },
  'protocols bgp var neighbor var remove-private-as' => {
      set => 'router bgp #3 ; neighbor #5 remove-private-AS',
      del => 'router bgp #3 ; no neighbor #5 remove-private-AS',
  },
  'protocols bgp var neighbor var route-map' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var route-map export' => {
      set => 'router bgp #3 ; neighbor #5 route-map #8 out',
      del => 'router bgp #3 ; no neighbor #5 route-map #8 out',
  },
  'protocols bgp var neighbor var route-map import' => {
      set => 'router bgp #3 ; neighbor #5 route-map #8 in',
      del => 'router bgp #3 ; no neighbor #5 route-map #8 in',
  },
  'protocols bgp var neighbor var route-reflector-client' => {
      set => 'router bgp #3 ; neighbor #5 route-reflector-client',
      del => 'router bgp #3 ; no neighbor #5 route-reflector-client',
  },
  'protocols bgp var neighbor var route-server-client' => {
      set => 'router bgp #3 ; neighbor #5 route-server-client',
      del => 'router bgp #3 ; no neighbor #5 route-server-client',
  },
  'protocols bgp var neighbor var shutdown' => {
      set => 'router bgp #3 ; neighbor #5 shutdown',
      del => 'router bgp #3 ; no neighbor #5 shutdown',
  },
  'protocols bgp var neighbor var soft-reconfiguration' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var soft-reconfiguration inbound' => {
      set => 'router bgp #3 ; neighbor #5 soft-reconfiguration inbound',
      del => 'router bgp #3 ; no neighbor #5 soft-reconfiguration inbound',
  },
  'protocols bgp var neighbor var strict-capability-match' => {
      set => 'router bgp #3 ; neighbor #5 strict-capability-match',
      del => 'router bgp #3 ; no neighbor #5 strict-capability-match',
  },
  'protocols bgp var neighbor var timers' => {
      set => 'router bgp #3 ; neighbor #5 timers @keepalive @holdtime',
      del => 'router bgp #3 ; no neighbor #5 timers',
  },
  'protocols bgp var neighbor var timers connect' => {
      set => 'router bgp #3 ; neighbor #5 timers connect #8',
      del => 'router bgp #3 ; no neighbor #5 timers connect',
  },
  'protocols bgp var neighbor var ttl-security' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var neighbor var ttl-security hops' => {
      set => 'router bgp #3 ; neighbor #5 ttl-security hops #8',
      del => 'router bgp #3 ; no neighbor #5 ttl-security hops #8',
  },
  'protocols bgp var neighbor var unsuppress-map' => {
      set => 'router bgp #3 ; neighbor #5 unsuppress-map #7',
      del => 'router bgp #3 ; no neighbor #5 unsuppress-map #7',
  },
  'protocols bgp var neighbor var update-source' => {
      set => 'router bgp #3 ; neighbor #5 update-source #7',
      del => 'router bgp #3 ; no neighbor #5 update-source',
  },
  'protocols bgp var neighbor var weight' => {
      set => 'router bgp #3 ; neighbor #5 weight #7',
      del => 'router bgp #3 ; no neighbor #5 weight',
  },
  'protocols bgp var network' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var network var' => {
      set => 'router bgp #3 ; network #5 ?backdoor',
      del => 'router bgp #3 ; no network #5',
  },
  'protocols bgp var network var route-map' => {
      set => 'router bgp #3 ; network #5 route-map #7',
      del => 'router bgp #3 ; no network #5 route-map #7 ; network #5',
  },
  'protocols bgp var parameters' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var parameters always-compare-med' => {
      set => 'router bgp #3 ; bgp always-compare-med',
      del => 'router bgp #3 ; no bgp always-compare-med',
  },
  'protocols bgp var parameters bestpath' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var parameters bestpath as-path' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var parameters bestpath as-path confed' => {
      set => 'router bgp #3 ; bgp bestpath as-path confed',
      del => 'router bgp #3 ; no bgp bestpath as-path confed',
  },
  'protocols bgp var parameters bestpath as-path ignore' => {
      set => 'router bgp #3 ; bgp bestpath as-path ignore',
      del => 'router bgp #3 ; no bgp bestpath as-path ignore',
  },
  'protocols bgp var parameters bestpath compare-routerid' => {
      set => 'router bgp #3 ; bgp bestpath compare-routerid',
      del => 'router bgp #3 ; no bgp bestpath compare-routerid',
  },
  'protocols bgp var parameters bestpath med' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var parameters bestpath med confed' => {
      set => 'router bgp #3 ; bgp bestpath med confed',
      del => 'router bgp #3 ; no bgp bestpath med confed',
  },
  'protocols bgp var parameters bestpath med missing-as-worst' => {
      set => 'router bgp #3 ; bgp bestpath med missing-as-worst',
      del => 'router bgp #3 ; no bgp bestpath med missing-as-worst',
  },
  'protocols bgp var parameters cluster-id' => {
      set => 'router bgp #3 ; bgp cluster-id #6',
      del => 'router bgp #3 ; no bgp cluster-id #6',
  },
  'protocols bgp var parameters confederation' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var parameters confederation identifier' => {
      set => 'router bgp #3 ; bgp confederation identifier #7',
      del => 'router bgp #3 ; no bgp confederation identifier #7',
  },
  'protocols bgp var parameters confederation peers' => {
      set => 'router bgp #3 ; bgp confederation peers #7',
      del => 'router bgp #3 ; no bgp confederation peers #7',
  },
  'protocols bgp var parameters dampening' => {
      set => 'router bgp #3 ; no bgp dampening ; bgp dampening @half-life @re-use @start-suppress-time @max-suppress-time',
      del => 'router bgp #3 ; no bgp dampening',
  },
  'protocols bgp var parameters default' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var parameters default local-pref' => {
      set => 'router bgp #3 ; bgp default local-preference #7',
      del => 'router bgp #3 ; no bgp default local-preference #7',
  },
  'protocols bgp var parameters default no-ipv4-unicast' => {
      set => 'router bgp #3 ; no bgp default ipv4-unicast',
      del => 'router bgp #3 ; bgp default ipv4-unicast',
  },
  'protocols bgp var parameters deterministic-med' => {
      set => 'router bgp #3 ; bgp deterministic-med',
      del => 'router bgp #3 ; no bgp deterministic-med',
  },
  'protocols bgp var parameters disable-network-import-check' => {
      set => 'router bgp #3 ; no bgp network import-check',
      del => 'router bgp #3 ; bgp network import-check',
  },
  'protocols bgp var parameters distance' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var parameters distance global' => {
      set => 'router bgp #3 ; distance bgp @external @internal @local',
      del => 'router bgp #3 ; no distance bgp',
  },
  'protocols bgp var parameters distance prefix' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var parameters distance prefix var' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var parameters distance prefix var distance' => {
      set => 'router bgp #3 ; distance #9 #7 ',
      del => 'router bgp #3 ; no distance #9 #7',
  },
  'protocols bgp var parameters enforce-first-as' => {
      set => 'router bgp #3 ; bgp enforce-first-as',
      del => 'router bgp #3 ; no bgp enforce-first-as',
  },
  'protocols bgp var parameters graceful-restart' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var parameters graceful-restart stalepath-time' => {
      set => 'router bgp #3 ; bgp graceful-restart stalepath-time #7',
      del => 'router bgp #3 ; no bgp graceful-restart stalepath-time #7',
  },
  'protocols bgp var parameters log-neighbor-changes' => {
      set => 'router bgp #3 ; bgp log-neighbor-changes',
      del => 'router bgp #3 ; no bgp log-neighbor-changes',
  },
  'protocols bgp var parameters no-client-to-client-reflection' => {
      set => 'router bgp #3 ; no bgp client-to-client reflection',
      del => 'router bgp #3 ; bgp client-to-client reflection',
  },
  'protocols bgp var parameters no-fast-external-failover' => {
      set => 'router bgp #3 ; no bgp fast-external-failover',
      del => 'router bgp #3 ; bgp fast-external-failover',
  },
  'protocols bgp var parameters router-id' => {
      set => 'router bgp #3 ; bgp router-id #6',
      del => 'router bgp #3 ; no bgp router-id #6',
  },
  'protocols bgp var parameters scan-time' => {
      set => 'router bgp #3 ; bgp scan-time #6',
      del => 'router bgp #3 ; no bgp scan-time #6',
  },
  'protocols bgp var peer-group' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var' => {
      set => 'router bgp #3 ; neighbor #5 peer-group',
      del => 'router bgp #3 ; no neighbor #5 peer-group',
      noerr => 'set',
  },
  'protocols bgp var peer-group var address-family' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var address-family ipv6-unicast' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 activate',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 activate',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast allowas-in' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 allowas-in',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 allowas-in',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast allowas-in number' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 allowas-in #10',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 allowas-in ; neighbor #5 allowas-in',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast attribute-unchanged' => {
      set => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 attribute-unchanged ; neighbor #5 attribute-unchanged ?as-path ?med ?next-hop',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 attribute-unchanged',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast capability' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var address-family ipv6-unicast capability dynamic' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 capability dynamic',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 capability dynamic',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast capability orf' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var address-family ipv6-unicast capability orf prefix-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var address-family ipv6-unicast capability orf prefix-list receive' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 capability orf prefix-list receive',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 capability orf prefix-list receive',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast capability orf prefix-list send' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 capability orf prefix-list send',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 capability orf prefix-list send',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast default-originate' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 default-originate',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 default-originate',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast default-originate route-map' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 default-originate route-map #10',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 default-originate route-map #10',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast disable-send-community' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var address-family ipv6-unicast disable-send-community extended' => {
      set => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 send-community extended',
      del => 'router bgp #3 ; address-family ipv6 ; neighbor #5 send-community extended',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast disable-send-community standard' => {
      set => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 send-community standard',
      del => 'router bgp #3 ; address-family ipv6 ; neighbor #5 send-community standard',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast distribute-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var address-family ipv6-unicast distribute-list export' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 distribute-list #10 out',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 distribute-list #10 out',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast distribute-list import' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 distribute-list #10 in',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 distribute-list #10 in',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast filter-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var address-family ipv6-unicast filter-list export' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 filter-list #10 out',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 filter-list #10 out',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast filter-list import' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 filter-list #10 in',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 filter-list #10 in',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast maximum-prefix' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 maximum-prefix #9',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 maximum-prefix #9',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast nexthop-local' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 nexthop-local unchanged',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 nexthop-local unchanged',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast nexthop-self' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 next-hop-self',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 next-hop-self',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast prefix-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var address-family ipv6-unicast prefix-list export' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 prefix-list #10 out',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 prefix-list #10 out',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast prefix-list import' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 prefix-list #10 in',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 prefix-list #10 in',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast remove-private-as' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 remove-private-AS',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 remove-private-AS',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast route-map' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var address-family ipv6-unicast route-map export' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 route-map #10 out',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 route-map #10 out',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast route-map import' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 route-map #10 in',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 route-map #10 in',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast route-reflector-client' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 route-reflector-client',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 route-reflector-client',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast route-server-client' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 route-server-client',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 route-server-client',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast soft-reconfiguration' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var address-family ipv6-unicast soft-reconfiguration inbound' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 soft-reconfiguration inbound',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 soft-reconfiguration inbound',
  },
  'protocols bgp var peer-group var address-family ipv6-unicast unsuppress-map' => {
      set => 'router bgp #3 ; address-family ipv6 ; neighbor #5 unsuppress-map #9',
      del => 'router bgp #3 ; address-family ipv6 ; no neighbor #5 unsuppress-map #9',
  },
  'protocols bgp var peer-group var allowas-in' => {
      set => 'router bgp #3 ; neighbor #5 allowas-in',
      del => 'router bgp #3 ; no neighbor #5 allowas-in',
  },
  'protocols bgp var peer-group var allowas-in number' => {
      set => 'router bgp #3 ; neighbor #5 allowas-in #8',
      del => 'router bgp #3 ; no neighbor #5 allowas-in ; neighbor #5 allowas-in',
  },
  'protocols bgp var peer-group var attribute-unchanged' => {
      set => 'router bgp #3 ; no neighbor #5 attribute-unchanged ; neighbor #5 attribute-unchanged ?as-path ?med ?next-hop',
      del => 'router bgp #3 ; no neighbor #5 attribute-unchanged ?as-path ?med ?next-hop',
  },
  'protocols bgp var peer-group var capability' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var capability dynamic' => {
      set => 'router bgp #3 ; neighbor #5 capability dynamic',
      del => 'router bgp #3 ; no neighbor #5 capability dynamic',
  },
  'protocols bgp var peer-group var capability orf' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var capability orf prefix-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var capability orf prefix-list receive' => {
      set => 'router bgp #3 ; neighbor #5 capability orf prefix-list receive',
      del => 'router bgp #3 ; no neighbor #5 capability orf prefix-list receive',
  },
  'protocols bgp var peer-group var capability orf prefix-list send' => {
      set => 'router bgp #3 ; neighbor #5 capability orf prefix-list send',
      del => 'router bgp #3 ; no neighbor #5 capability orf prefix-list send',
  },
  ## Note that the activate will need to be moved when we migrate to 
  ## supporting a single IP version in a peering session.
  'protocols bgp var peer-group var default-originate' => {
      set => 'router bgp #3 ; neighbor #5 activate ; neighbor #5 default-originate',
      del => 'router bgp #3 ; no neighbor #5 default-originate',
  },
  'protocols bgp var peer-group var default-originate route-map' => {
      set => 'router bgp #3 ; neighbor #5 activate ; neighbor #5 default-originate route-map #8',
      del => 'router bgp #3 ; no neighbor #5 default-originate route-map #8',
  },
  'protocols bgp var peer-group var disable-capability-negotiation' => {
      set => 'router bgp #3 ; neighbor #5 dont-capability-negotiate',
      del => 'router bgp #3 ; no neighbor #5 dont-capability-negotiate',
  },
  'protocols bgp var peer-group var disable-connected-check' => {
      set => 'router bgp #3 ; neighbor #5 disable-connected-check',
      del => 'router bgp #3 ; no neighbor #5 disable-connected-check',
  },
  'protocols bgp var peer-group var disable-send-community' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var disable-send-community extended' => {
      set => 'router bgp #3 ; no neighbor #5 send-community extended',
      del => 'router bgp #3 ; neighbor #5 send-community extended',
  },
  'protocols bgp var peer-group var disable-send-community standard' => {
      set => 'router bgp #3 ; no neighbor #5 send-community standard',
      del => 'router bgp #3 ; neighbor #5 send-community standard',
  },
  'protocols bgp var peer-group var distribute-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var distribute-list export' => {
      set => 'router bgp #3 ; neighbor #5 distribute-list #8 out',
      del => 'router bgp #3 ; no neighbor #5 distribute-list #8 out',
  },
  'protocols bgp var peer-group var distribute-list import' => {
      set => 'router bgp #3 ; neighbor #5 distribute-list #8 in',
      del => 'router bgp #3 ; no neighbor #5 distribute-list #8 in',
  },
  'protocols bgp var peer-group var ebgp-multihop' => {
      set => 'router bgp #3 ; neighbor #5 ebgp-multihop #7',
      del => 'router bgp #3 ; no neighbor #5 ebgp-multihop #7',
  },
  'protocols bgp var peer-group var filter-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var filter-list export' => {
      set => 'router bgp #3 ; neighbor #5 filter-list #8 out',
      del => 'router bgp #3 ; no neighbor #5 filter-list #8 out',
  },
  'protocols bgp var peer-group var filter-list import' => {
      set => 'router bgp #3 ; neighbor #5 filter-list #8 in',
      del => 'router bgp #3 ; no neighbor #5 filter-list #8 in',
  },
  'protocols bgp var peer-group var local-as' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var local-as var' => {
      set => 'router bgp #3 ; no neighbor #5 local-as ; neighbor #5 local-as #7',
      del => 'router bgp #3 ; no neighbor #5 local-as #7',
  },
  'protocols bgp var peer-group var local-as var no-prepend' => {
      set => 'router bgp #3 ; no neighbor #5 local-as #7 ; neighbor #5 local-as #7i no-prepend',
      del => 'router bgp #3 ; no neighbor #5 local-as #7 no-prepend ; neighbor #5 local-as #7',
  },
  'protocols bgp var peer-group var maximum-prefix' => {
      set => 'router bgp #3 ; neighbor #5 maximum-prefix #7',
      del => 'router bgp #3 ; no neighbor #5 maximum-prefix #7',
  },
  'protocols bgp var peer-group var nexthop-self' => {
      set => 'router bgp #3 ; neighbor #5 next-hop-self',
      del => 'router bgp #3 ; no neighbor #5 next-hop-self',
  },
  'protocols bgp var peer-group var override-capability' => {
      set => 'router bgp #3 ; neighbor #5 override-capability',
      del => 'router bgp #3 ; no neighbor #5 override-capability',
  },
  'protocols bgp var peer-group var passive' => {
      set => 'router bgp #3 ; neighbor #5 passive',
      del => 'router bgp #3 ; no neighbor #5 passive',
  },
  'protocols bgp var peer-group var password' => {
      set => 'router bgp #3 ; neighbor #5 password #7',
      del => 'router bgp #3 ; no neighbor #5 password',
  },
  'protocols bgp var peer-group var port' => {
      set => 'router bgp #3 ; neighbor #5 port #7',
      del => 'router bgp #3 ; no neighbor #5 port #7',
  },
  'protocols bgp var peer-group var prefix-list' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var prefix-list export' => {
      set => 'router bgp #3 ; neighbor #5 prefix-list #8 out',
      del => 'router bgp #3 ; no neighbor #5 prefix-list #8 out',
  },
  'protocols bgp var peer-group var prefix-list import' => {
      set => 'router bgp #3 ; neighbor #5 prefix-list #8 in',
      del => 'router bgp #3 ; no neighbor #5 prefix-list #8 in',
  },
  'protocols bgp var peer-group var remote-as' => {
      set => 'router bgp #3 ; neighbor #5 peer-group ; neighbor #5 remote-as #7',
      del => 'router bgp #3 ; no neighbor #5 remote-as #7',
      noerr => 'set',
  },
  'protocols bgp var peer-group var remove-private-as' => {
      set => 'router bgp #3 ; neighbor #5 remove-private-AS',
      del => 'router bgp #3 ; no neighbor #5 remove-private-AS',
  },
  'protocols bgp var peer-group var route-map' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var route-map export' => {
      set => 'router bgp #3 ; neighbor #5 route-map #8 out',
      del => 'router bgp #3 ; no neighbor #5 route-map #8 out',
  },
  'protocols bgp var peer-group var route-map import' => {
      set => 'router bgp #3 ; neighbor #5 route-map #8 in',
      del => 'router bgp #3 ; no neighbor #5 route-map #8 in',
  },
  'protocols bgp var peer-group var route-reflector-client' => {
      set => 'router bgp #3 ; neighbor #5 route-reflector-client',
      del => 'router bgp #3 ; no neighbor #5 route-reflector-client',
  },
  'protocols bgp var peer-group var route-server-client' => {
      set => 'router bgp #3 ; neighbor #5 route-server-client',
      del => 'router bgp #3 ; no neighbor #5 route-server-client',
  },
  'protocols bgp var peer-group var shutdown' => {
      set => 'router bgp #3 ; neighbor #5 shutdown',
      del => 'router bgp #3 ; no neighbor #5 shutdown',
  },
  'protocols bgp var peer-group var soft-reconfiguration' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var soft-reconfiguration inbound' => {
      set => 'router bgp #3 ; neighbor #5 soft-reconfiguration inbound',
      del => 'router bgp #3 ; no neighbor #5 soft-reconfiguration inbound',
  },
  'protocols bgp var peer-group var timers' => {
      set => 'router bgp #3 ; neighbor #5 timers @keepalive @holdtime',
      del => 'router bgp #3 ; no neighbor #5 timers',
  },
  'protocols bgp var peer-group var timers connect' => {
      set => 'router bgp #3 ; neighbor #5 timers connect #8',
      del => 'router bgp #3 ; no neighbor #5 timers connect #8',
  },
  'protocols bgp var peer-group var ttl-security' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var peer-group var ttl-security hops' => {
      set => 'router bgp #3 ; neighbor #5 ttl-security hops #8',
      del => 'router bgp #3 ; no neighbor #5 ttl-security hops #8',
  },
  'protocols bgp var peer-group var unsuppress-map' => {
      set => 'router bgp #3 ; neighbor #5 unsuppress-map #7',
      del => 'router bgp #3 ; no neighbor #5 unsuppress-map #7',
  },
  'protocols bgp var peer-group var update-source' => {
      set => 'router bgp #3 ; neighbor #5 update-source #7',
      del => 'router bgp #3 ; no neighbor #5 update-source',
  },
  'protocols bgp var peer-group var weight' => {
      set => 'router bgp #3 ; neighbor #5 weight #7',
      del => 'router bgp #3 ; no neighbor #5 weight #7',
  },
  'protocols bgp var redistribute' => {
      set => undef,
      del => undef,
  },
  'protocols bgp var redistribute connected' => {
      set => 'router bgp #3 ; redistribute connected ?route-map ?metric',
      del => 'router bgp #3 ; no redistribute connected',
      noerr => 'set',
  },
  'protocols bgp var redistribute connected metric' => {
      set => 'router bgp #3 ; redistribute connected metric #7',
      del => 'router bgp #3 ; no redistribute connected metric #7',
      noerr => 'set',
  },
  'protocols bgp var redistribute connected route-map' => {
      set => 'router bgp #3 ; redistribute connected route-map #7',
      del => 'router bgp #3 ; no redistribute connected route-map #7',
      noerr => 'set',
  },
  'protocols bgp var redistribute kernel' => {
      set => 'router bgp #3 ; no redistribute kernel ; redistribute kernel ?route-map ?metric',
      del => 'router bgp #3 ; no redistribute kernel',
      noerr => 'set',
  },
  'protocols bgp var redistribute ospf' => {
      set => 'router bgp #3 ; no redistribute ospf ; redistribute ospf ?route-map ?metric',
      del => 'router bgp #3 ; no redistribute ospf',
      noerr => 'set',
  },
  'protocols bgp var redistribute rip' => {
      set => 'router bgp #3 ; no redistribute rip ; redistribute rip ?route-map ?metric',
      del => 'router bgp #3 ; no redistribute rip',
      noerr => 'set',
  },
  'protocols bgp var redistribute static' => {
      set => 'router bgp #3 ; no redistribute static ; redistribute static ?route-map ?metric',
      del => 'router bgp #3 ; no redistribute static',
      noerr => 'set',
  },
  'protocols bgp var timers' => {
      set => 'router bgp #3 ; timers bgp @keepalive @holdtime',
      del => 'router bgp #3 ; no timers bgp',
  },
);

if ( ! -e "/usr/sbin/zebra" ) {
  $qcom{'protocols bgp var neighbor var remote-as'}{'set'} = 'router bgp #3 ; neighbor #5 remote-as #7';
}

my ( $pg, $as, $neighbor );
my ( $main, $peername, $isneighbor, $checkpeergroups, $checkpeergroups6, $checksource, 
     $isiBGPpeer, $wasiBGPpeer, $confedibgpasn, $listpeergroups);

GetOptions(
    "peergroup=s"             => \$pg,
    "as=s"                    => \$as,
    "neighbor=s"              => \$neighbor,
    "check-peergroup-name=s"  => \$peername,
    "check-neighbor-ip"       => \$isneighbor,
    "check-peer-groups"       => \$checkpeergroups,
    "check-peer-groups-6"     => \$checkpeergroups6,
    "check-source=s"	      => \$checksource,
    "is-iBGP"		      => \$isiBGPpeer,
    "was-iBGP"                => \$wasiBGPpeer,
    "confed-iBGP-ASN-check=s" => \$confedibgpasn,
    "list-peer-groups"        => \$listpeergroups,
    "main"                    => \$main,
);

main()					    if ($main);
check_peergroup_name($peername)	  	    if ($peername);
check_neighbor_ip($neighbor)                if ($isneighbor);
check_for_peer_groups( $pg, $as )	    if ($checkpeergroups);
check_for_peer_groups6( $pg, $as )	    if ($checkpeergroups6);
check_source($checksource)	            if ($checksource);
confed_iBGP_ASN($as, $confedibgpasn)        if ($confedibgpasn);
is_iBGP_peer($neighbor, $as)          	    if ($isiBGPpeer);
was_iBGP_peer($neighbor, $as)               if ($wasiBGPpeer);
list_peer_groups($as)                       if ($listpeergroups);

exit 0;

sub list_peer_groups {
   my $as = shift;
   my $config = new Vyatta::Config;

   $config->setLevel("protocols bgp $as peer-group");
   my @nodes = $config->listNodes();
   foreach my $node (@nodes) { print "$node "; }
   return;
}

# Make sure the peer IP isn't a local system IP
sub check_neighbor_ip {
    my $neighbor = shift;

    die "Can't set neighbor address to local system IP.\n"
	if (is_local_address($neighbor));
    
    exit 0;
}

# Make sure the peer-group name is properly formatted
sub check_peergroup_name {
    my $neighbor = shift;

    $_ = $neighbor;
    my $version = is_ip_v4_or_v6($neighbor);
    if ( ( defined($version) ) || (/[\s\W]/g) ) {
        die "malformed peer-group name $neighbor\n";
    }

    # Quagga treats the first byte as a potential IPv6 address
    # so we can't use it as a peer group name.  So let's check for it.
    if (/^[A-Fa-f]{1,4}$/) {
		die "malformed peer-group name $neighbor\n";
    }
}

# Make sure we aren't deleteing a peer-group that has
# neighbors configured to it
sub check_for_peer_groups6 {
    my $config = new Vyatta::Config;
    my $pg     = shift;
    die "Peer group not defined\n" unless $pg;
    my $as = shift;
    die "AS not defined\n" unless $as;
    my @peers;

    # get the list of neighbors and see if they have a peer-group set
    $config->setLevel("protocols bgp $as neighbor");
    my @neighbors = $config->listNodes();

    foreach my $node (@neighbors) {
        my $peergroup6 = $config->returnValue("$node address-family ipv6-unicast peer-group");
        if (defined($peergroup6) && ($peergroup6 eq $pg)) 
        { 
             push @peers, $node; 
        }
    }

    # if we found peers in the previous statements
    # notify an return errors
    if (@peers) {
        foreach my $node (@peers) {
            print "neighbor $node uses ipv6 peer-group $pg\n";
        }

	die "please delete these peers before removing the peer-group\n";
    }
}

# Make sure we aren't deleteing a peer-group that has
# neighbors configured to it
sub check_for_peer_groups {
    my $config = new Vyatta::Config;
    my $pg     = shift;
    die "Peer group not defined\n" unless $pg;
    my $as = shift;
    die "AS not defined\n" unless $as;
    my @peers;

    # get the list of neighbors and see if they have a peer-group set
    $config->setLevel("protocols bgp $as neighbor");
    my @neighbors = $config->listNodes();

    foreach my $node (@neighbors) {
        my $peergroup = $config->returnValue("$node peer-group");
        if ((defined $peergroup) && ($peergroup eq $pg)) { push @peers, $node; }
    }

    # if we found peers in the previous statements
    # notify an return errors
    if (@peers) {
        foreach my $node (@peers) {
            print "neighbor $node uses peer-group $pg\n";
        }

	die "please delete these peers before removing the peer-group\n";
    }
}

# function to verify changing remote-as from/to i/eBGP
# there are two types of parameter checks we need to do.  The first should happen
# when the affected parameter is created/changed. Those checks should happen in  
# the syntax and commit statements in the node.defs for those specific params since
# they can be updated individually. The params should be checked again if the remote-as
# changes.
# This funtion handles changes in the remote-as and/or peer-group 
sub bgp_type_change {
    my ($neighbor, $as, $ntype) =@_;
    my $config = new Vyatta::Config;
    $config->setLevel('protocols bgp');

    if ( ("$ntype" ne "neighbor") && ("$ntype" ne "peer-group") ) {
      return -1;
    }

    # check if changing from iBGP to eBGP
    if ( (iBGP_peer(1, $neighbor, $as, $ntype)) && (! iBGP_peer(0, $neighbor, $as, $ntype)) ) {
      if ( $config->exists("$as $ntype $neighbor route-reflector-client") ||
           $config->exists("$as $ntype $neighbor address-family ipv6-unicast route-reflector-client") ) {
        return "can not set route-reflector-client and an eBGP remote-as at the same time\n";
      }
    }

    # check if changing from eBGP to iBGP
    if ( (! iBGP_peer(1, $neighbor, $as, $ntype)) && (iBGP_peer(0, $neighbor, $as, $ntype)) ) {
      if ($config->exists("$as $ntype $neighbor ebgp-multihop")) {
        return "can not set ebgp-multihop and an iBGP remote-as at the same time\n";
      }
      if ($config->exists("$as $ntype $neighbor ttl-security")) {
        return "can not set ttl-security and an iBGP remote-as at the same time\n";
      }
      if ($config->exists("$as $ntype $neighbor local-as")) {
        return "can not set local-as and an iBGP remote-as at the same time\n";
      }
    }
}

sub checkBannedPeerGroupParameters
{
	my ($level, $protocol) = @_;
	unless ($protocol == 4 || $protocol == 6) {
		return -1;
	}
	
	my @bannedlist = ('advertisement-interval', 'attribute-unchanged', 'capability orf',
						'default-originate', 'distribute-list export', 'filter-list export',
						'nexthop-self', 'prefix-list export', 'remove-private-as',
						'route-map export', 'route-reflector-client', 'route-server-client',
						'disable-send-community', 'timers', 'ttl-security', 'unsuppress-map');
	
	my @globalbannedlist = ('local-as');
	
	my $config = new Vyatta::Config;
	$config->setLevel("protocols bgp $level");

	foreach my $node (@globalbannedlist) {
		if ($config->exists($node)) {
			die "[ protocols bgp $level ]\n  parameter $node is incompatible with a neighbor in a peer-group\n";
		}
	}
	if ($protocol == 6) {
		$config->setLevel("protocols bgp $level address-family ipv6-unicast");
	}	
	foreach my $node (@bannedlist) {
		if ($config->exists($node)) {
			die "[ protocols bgp $level ]\n  parameter $node is incompatible with a neighbor in a peer-group\n";
		}
	}
	return 1;
}

sub checkOverwritePeerGroupParameters
{
	my ($qconfig_ref, $level, $protocol) = @_;
	my $ret = 0;
	
	unless ($protocol == 4 || $protocol == 6) {
		return -1;
	}
	
	my @overwritelist = ('allowas-in', 'allowas-in number', 'capability dynamic', 
							'distribute-list import', 'filter-list import', 'maximum-prefix', 
							'port', 'prefix-list import', 'route-map import', 
							'soft-reconfiguration inbound', 'strict-capability-match');
							
	my @globaloverwritelist = ('disable-capability-negotiation', 'disable-connected-check',
								'ebgp-multihop', 'override-capability', 'passive', 'password',
								'shutdown', 'update-source', 'weight');

	my $config = new Vyatta::Config;
	$config->setLevel("protocols bgp $level");

	foreach my $node (@globaloverwritelist) {
		if ($config->exists($node)) {
			$$qconfig_ref->reInsertNode("protocols bgp $level $node");
			$ret++;
		}
	}
	if ($protocol == 6) {
		$level .= " address-family ipv6-unicast";
		$config->setLevel("protocols bgp $level");
	}
	foreach my $node (@overwritelist) {
		if ($config->exists($node)) {
			$$qconfig_ref->reInsertNode("protocols bgp $level $node");
			$ret++;
		}
	}
	return $ret;
}

# check that changed neighbors have a remote-as or peer-group defined
# and that all permutations of parameters and BGP type are correct
sub check_neighbor_parameters 
{
    my $qconfig_ref = shift;
    my $config = new Vyatta::Config;
    $config->setLevel('protocols bgp');

    my @asns = $config->listNodes();
    foreach my $as (@asns) {
      # check peer-groups if they have changed
      my @peergroups = $config->listNodes("$as peer-group");
      foreach my $peergroup (@peergroups) {
          next unless ($config->isChanged("$as peer-group $peergroup"));

          # if we delete the remote-as in the pg, make sure all neighbors have a remote-as defined
          if ($config->isDeleted("$as peer-group $peergroup remote-as")) {
            my @neighbors = $config->listNodes("$as neighbor");
            foreach my $neighbor (@neighbors) {
              my $pgmembership = $config->returnValue("$as neighbor $neighbor peer-group");
              if ( (defined $pgmembership) && ("$pgmembership" eq "$peergroup") ) {
                my $remoteas = $config->returnValue("$as neighbor $neighbor remote-as");
                if (! defined $remoteas) {
                  die "[ protocols bgp $as peer-group $neighbor ]\n  can't delete the remote-as in peer-group without setting remote-as in member neighbors\n"
                }
              }
            }
          }

          # check asn type change
          my $error = bgp_type_change($peergroup, $as, "peer-group");
          if ($error) { die "[ protocols bgp $as peer-group $peergroup ]\n  $error\n"; }

          # remote-as can't be defined in both pg and neighbor at the same time
          my $pgremoteas = $config->returnValue("$as peer-group $peergroup remote-as");
          if ($pgremoteas) {
            my @neighbors = $config->listNodes("$as neighbor");
            foreach my $neighbor (@neighbors) {
              my $pgmembership = $config->returnValue("$as neighbor $neighbor peer-group");
              if ((defined $pgmembership) && ("$pgmembership" eq "$peergroup")) {
                my $remoteas = $config->returnValue("$as neighbor $neighbor remote-as");
                if (defined $remoteas && defined $pgremoteas) {
                  die "[ protocols bgp $as peer-group $neighbor ]\n  must not define remote-as in both neighbor and peer-group\n"
                }
              }
            }
          }

          # check if a peer-group overwrite parameter was changed and resubmit
          my @neighbors = $config->listNodes("$as neighbor");
          foreach my $neighbor (@neighbors) {
            my $pg = $config->returnValue("$as neighbor $neighbor peer-group");
            if (defined $pg && ($pg eq "$peergroup")) {
              checkOverwritePeerGroupParameters($qconfig_ref, "$as neighbor $neighbor", 4);
            }
          }
      } ## end foreach my $peergroup (@peergroups)

      # check neighbor if remote-as or peer-group has been changed
      my @neighbors = $config->listNodes("$as neighbor");
      
      foreach my $neighbor (@neighbors) {
      	# check that remote-as exists
      	if ($config->isChanged("$as neighbor $neighbor remote-as") ||
	    ! $config->exists("$as neighbor $neighbor remote-as")) {
	    # remote-as checks: Make sure the neighbor has a remote-as defined locally or in the peer-group
	    my ($remoteas, $peergroup, $peergroupas, $peergroup6, $peergroup6as);
	    $remoteas = $config->returnValue("$as neighbor $neighbor remote-as");
	    if ($config->exists("$as neighbor $neighbor peer-group")) {
                if ($config->exists("$as parameters default no-ipv4-unicast")) {
                    die "[ protocols bgp $as neighbor $neighbor ]\n  peer-group defined but ipv4-unicast is disabled\n";
                }
		$peergroup = $config->returnValue("$as neighbor $neighbor peer-group");
            	if ($config->exists("$as peer-group $peergroup remote-as")) {
		    $peergroupas = $config->returnValue("$as peer-group $peergroup remote-as");
            	}
	    }
            if ($config->exists("$as neighbor $neighbor address-family ipv6-unicast peer-group")) {
		$peergroup6 = $config->returnValue("$as neighbor $neighbor address-family ipv6-unicast peer-group");
            	if ($config->exists("$as peer-group $peergroup6 remote-as")
                    && $config->exists("$as peer-group $peergroup6 address-family ipv6-unicast")) {
		    $peergroup6as = $config->returnValue("$as peer-group $peergroup6 remote-as");
            	}
	    }

	    die "[ protocols bgp $as neighbor $neighbor ]\n  must set remote-as or peer-group with remote-as defined\n"
		if ((!defined($remoteas) && !defined($peergroupas)) && !$config->exists("$as parameters default no-ipv4-unicast"));

	    die "[ protocols bgp $as neighbor $neighbor ]\n  must set remote-as or address-family ipv6-unicast peer-group"
               ." with remote-as defined\n"
		if ($config->exists("$as neighbor $neighbor address-family ipv6-unicast") && 
                   (!defined($peergroup6as) && !defined($remoteas)));

	    die "[ protocols bgp $as neighbor $neighbor ]\n  remote-as should not be defined in both neighbor and peer-group\n"
            	if ($remoteas && $peergroupas);
            
        } ## end remote-as checks
        
        # Check if changing BGP peer type from/to i/eBGP
        my $error = bgp_type_change($neighbor, $as, "neighbor");
        if ($error) { die "[ protocols bgp $as neighbor $neighbor ]\n  $error\n"; }

	# If the peer-group has changed since the last commit, update overwritable nodes
	# We do this because Quagga removes nodes silently while vyatta-cfg does not.
	# check IPv4 peer-group
	if ($config->exists("$as neighbor $neighbor peer-group")) {
	    checkBannedPeerGroupParameters("$as neighbor $neighbor", 4);
	}
	if ($config->isChanged("$as neighbor $neighbor peer-group")) {
	    checkOverwritePeerGroupParameters($qconfig_ref, "$as neighbor $neighbor", 4);
	}
		
	# check IPv6 peer-group
	if ($config->exists("$as neighbor $neighbor address-family ipv6-unicast peer-group")) {
	    checkBannedPeerGroupParameters("$as neighbor $neighbor", 6);
	}
	if ($config->isChanged("$as neighbor $neighbor address-family ipv6-unicast peer-group")) {
	    checkOverwritePeerGroupParameters($qconfig_ref, "$as neighbor $neighbor", 6);
        }
      } ## end foreach my $neighbor (@neighbors)
    } ## end foreach my $as (@asns)
}

# check to see if adding this ASN to confederations 
# will make a peer an iBGP peer
sub confed_iBGP_ASN {
    my ($as, $testas) = @_;
    if ("$as" eq "$testas") { exit 1 ; }

    my $config = new Vyatta::Config;
    $config->setLevel("protocols bgp $as");

    #my @neighbors = $config->listNodes('neighbor');
    my @neighbors = $config->listOrigNodes('neighbor');
    foreach my $neighbor (@neighbors) {
      my $remoteas = $config->returnValue("neighbor $neighbor remote-as");
      if ("$testas" eq "$remoteas") {
        exit 1;
      }
    }
    
    return;
}

sub is_iBGP_peer {
    my ($neighbor, $as) = @_;

    my $return = iBGP_peer(0, $neighbor, $as, "neighbor");
    if ($return > 0) { exit 1; }
    elsif ($return < 0) { print "Unable to determine original ASN for neighbhor $neighbor\n"; }
    exit 0; 
}

sub was_iBGP_peer {
    my ($neighbor, $as) = @_;

    if (iBGP_peer(1, $neighbor, $as, "neighbor") >= 1) { exit 1; }
    exit 0; 
}
    
# is this peer an iBGP peer?
sub iBGP_peer {
    my ($orig, $neighbor, $as, $ntype) = @_;
    my $config = new Vyatta::Config;
    my @ibgp_as;
    my $neighbor_as;

    $config->setLevel("protocols bgp $as");

    my $exists = sub { $config->exists(@_) };
    my $returnValue = sub { $config->returnValue(@_) };
    my $returnValues = sub { $config->returnValues(@_) };

    if ($orig) {
      $exists = sub { $config->existsOrig(@_) };
      $returnValue = sub { $config->returnOrigValue(@_) };
      $returnValues = sub { $config->returnOrigValues(@_) };
    }

    # find my local ASN for this neighbor
    # it's either explicitly defined or in the peer-group
    if ($exists->("$ntype $neighbor remote-as")) {
      $neighbor_as = $returnValue->("$ntype $neighbor remote-as");
    }
    elsif ( ("$ntype" eq "neighbor") && ($exists->("neighbor $neighbor peer-group")) ) {
      my $peergroup = $returnValue->("neighbor $neighbor peer-group");
      if ($exists->("peer-group $peergroup remote-as")) {
        my $peergroup = $returnValue->("neighbor $neighbor peer-group");
        $neighbor_as = $returnValue->("peer-group $peergroup remote-as");
      }
      else {
	return -1;
      }
    }
    else {
      return -1;
    }

    # now find my possible local ASNs.  Confederation ASNs are first.
    if ($exists->('parameters confederation peers')) {
      @ibgp_as = $returnValues->('parameters confederation peers');
    }
    
    # push router local ASN on the stack
    push @ibgp_as, $as;

    # and compare neighbor local as to possible local ASNs
    foreach my $localas (@ibgp_as) {
      if ("$localas" eq "$neighbor_as") {
        return 1;
      }
    }

    return 0;
}

# check that value is either an IPV4 address on system or an interface
sub check_source {
    my $src = shift;
    my $ip = new NetAddr::IP::Lite($src);
    
    if ($ip) {
	my $found = grep { my $a = new NetAddr::IP::Lite($_);
			   $a->addr() eq $ip->addr() } Vyatta::Misc::getIP();
	die "IP address $ip does not exist on this system\n" if ($found == 0);
    } else {
	my $found = grep { $_ eq $src } Vyatta::Misc::getInterfaces();
	die "Interface $src does not exist on the system\n" if ($found == 0);
    }
}

sub main 
{
   # initialize the Quagga Config object with data from Vyatta config tree
   my $qconfig = new Vyatta::Quagga::Config('protocols', \%qcom);

   # debug routines
   #$qconfig->setDebugLevel('3');
   #$qconfig->_reInitialize();

   # check that all changed neighbors have a proper remote-as or peer-group defined
   # and that migrations to/from iBGP eBGP are valid
   check_neighbor_parameters(\$qconfig);

   ## deletes with priority
   # delete everything in neighbor, ordered nodes last 
   my @ordered = ('remote-as', 'peer-group', 'shutdown', 'route-map', 'prefix-list', 'filter-list', 'distribute-list', 'unsuppress-map');  
   # notice the extra space in the level string.  keeps the parent from being deleted.
   $qconfig->deleteConfigTreeRecursive('protocols bgp var neighbor var ', undef, \@ordered) || die "exiting $?\n";
   $qconfig->deleteConfigTreeRecursive('protocols bgp var peer-group var ', undef, \@ordered) || die "exiting $?\n";
   $qconfig->deleteConfigTreeRecursive('protocols bgp') || die "exiting $?\n";

   ## sets with priority
   $qconfig->setConfigTreeRecursive('protocols bgp var parameters') || die "exiting $?\n";
   $qconfig->setConfigTreeRecursive('protocols bgp var peer-group', undef, \@ordered) || die "exiting $?\n";
   $qconfig->setConfigTreeRecursive('protocols bgp var neighbor var remote-as', undef, \@ordered) || die "exiting $?\n";
   $qconfig->setConfigTreeRecursive('protocols bgp var neighbor var address-family ipv6-unicast peer-group'
                                    , undef, \@ordered) || die "exiting $?\n";
   $qconfig->setConfigTreeRecursive('protocols bgp var neighbor var address-family ipv6-unicast'
                                    , undef, \@ordered) || die "exiting $?\n";
   $qconfig->setConfigTreeRecursive('protocols bgp var neighbor var ', undef, \@ordered) || die "exiting $?\n";
   $qconfig->setConfigTreeRecursive('protocols bgp') || die "exiting $?\n";
}
