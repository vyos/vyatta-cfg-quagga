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
  "protocols" => undef,
  "protocols bgp" => undef,
  "protocols bgp var" => "router bgp #3",
  "protocols bgp var aggregate-address" => undef,
  "protocols bgp var aggregate-address var" => "router bgp #3 ; no aggregate-address #5 ; aggregate-address #5 ?as-set ?summary-only",
  "protocols bgp var address-family" => undef,
  "protocols bgp var address-family ipv6-unicast" => undef,
  "protocols bgp var address-family ipv6-unicast aggregate-address" => undef,
  "protocols bgp var address-family ipv6-unicast aggregate-address var" => "router bgp #3 ; no ipv6 bgp aggregate-address #7 ; ipv6 bgp aggregate-address #7 ?summary-only",
  "protocols bgp var address-family ipv6-unicast network" => "router bgp #3 ; no ipv6 bgp network #7 ; ipv6 bgp network #7",
  "protocols bgp var address-family ipv6-unicast redistribute" => undef,
  "protocols bgp var address-family ipv6-unicast redistribute connected" => "router bgp #3 ; address-family ipv6 ; redistribute connected",
  "protocols bgp var address-family ipv6-unicast redistribute connected metric" => "router bgp #3 ; address-family ipv6 ; redistribute connected metric #9",
  "protocols bgp var address-family ipv6-unicast redistribute connected route-map" => "router bgp #3 ; address-family ipv6 ; redistribute connected route-map #9",
  "protocols bgp var address-family ipv6-unicast redistribute kernel" => "router bgp #3 ; address-family ipv6 ; redistribute kernel",
  "protocols bgp var address-family ipv6-unicast redistribute kernel metric" => "router bgp #3 ; address-family ipv6 ; redistribute kernel metric #9",
  "protocols bgp var address-family ipv6-unicast redistribute kernel route-map" => "router bgp #3 ; address-family ipv6 ; redistribute kernel route-map #9",
  "protocols bgp var address-family ipv6-unicast redistribute ospfv3" => "router bgp #3 ; address-family ipv6 ; redistribute ospfv3",
  "protocols bgp var address-family ipv6-unicast redistribute ospfv3 metric" => "router bgp #3 ; address-family ipv6 ; redistribute ospfv3 metric #9",
  "protocols bgp var address-family ipv6-unicast redistribute ospfv3 route-map" => "router bgp #3 ; address-family ipv6 ; redistribute ospfv3 route-map #9",
  "protocols bgp var address-family ipv6-unicast redistribute ripng" => "router bgp #3 ; address-family ipv6 ; redistribute ripng",
  "protocols bgp var address-family ipv6-unicast redistribute ripng metric" => "router bgp #3 ; address-family ipv6 ; redistribute ripng metric #9",
  "protocols bgp var address-family ipv6-unicast redistribute ripng route-map" => "router bgp #3 ; address-family ipv6 ; redistribute ripng route-map #9",
  "protocols bgp var address-family ipv6-unicast redistribute static" => "router bgp #3 ; address-family ipv6 ; redistribute static",
  "protocols bgp var address-family ipv6-unicast redistribute static metric" => "router bgp #3 ; address-family ipv6 ; redistribute static metric #9",
  "protocols bgp var address-family ipv6-unicast redistribute static route-map" => "router bgp #3 ; address-family ipv6 ; redistribute static route-map #9",
  "protocols bgp var neighbor" => undef,
  "protocols bgp var neighbor var" => "router bgp #3 ; neighbor #5",
  "protocols bgp var neighbor var address-family" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast" => "router bgp #3 ; address-family ipv6 ; neighbor #5 activate",,
  "protocols bgp var neighbor var address-family ipv6-unicast allowas-in" => "router bgp #3 ; address-family ipv6 ; neighbor #5 allowas-in",
  "protocols bgp var neighbor var address-family ipv6-unicast attribute-unchanged" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 attribute-unchanged ; neighbor #5 attribute-unchanged ?as-path ?med ?next-hop",
  "protocols bgp var neighbor var address-family ipv6-unicast capability" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast capability dynamic" => "router bgp #3 ; address-family ipv6 ; neighbor #5 capability dynamic",
  "protocols bgp var neighbor var address-family ipv6-unicast capability orf" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast capability orf prefix-list" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast capability orf prefix-list receive" => "router bgp #3 ; address-family ipv6 ; neighbor #5 capability orf prefix-list receive",
  "protocols bgp var neighbor var address-family ipv6-unicast capability orf prefix-list send" => "router bgp #3 ; address-family ipv6 ; neighbor #5 capability orf prefix-list send",
  "protocols bgp var neighbor var address-family ipv6-unicast default-originate" => "router bgp #3 ; address-family ipv6 ; neighbor #5 default-originate",
  "protocols bgp var neighbor var address-family ipv6-unicast default-originate route-map" => "router bgp #3 ; address-family ipv6 ; neighbor #5 default-originate route-map #10",
  "protocols bgp var neighbor var address-family ipv6-unicast disable-send-community" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast disable-send-community extended" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 send-community extended",
  "protocols bgp var neighbor var address-family ipv6-unicast disable-send-community standard" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 send-community standard",
  "protocols bgp var neighbor var address-family ipv6-unicast distribute-list" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast distribute-list export" => "router bgp #3 ; address-family ipv6 ; neighbor #5 distribute-list #10 out",
  "protocols bgp var neighbor var address-family ipv6-unicast distribute-list import" => "router bgp #3 ; address-family ipv6 ; neighbor #5 distribute-list #10 in",
  "protocols bgp var neighbor var address-family ipv6-unicast filter-list" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast filter-list export" => "router bgp #3 ; address-family ipv6 ; neighbor #5 filter-list #10 out",
  "protocols bgp var neighbor var address-family ipv6-unicast filter-list import" => "router bgp #3 ; address-family ipv6 ; neighbor #5 filter-list #10 in",
  "protocols bgp var neighbor var address-family ipv6-unicast maximum-prefix" => "router bgp #3 ; address-family ipv6 ; neighbor #5 maximum-prefix #9",
  "protocols bgp var neighbor var address-family ipv6-unicast nexthop-local" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast nexthop-local" => "router bgp #3 ; address-family ipv6 ; neighbor #5 nexthop-local unchanged",
  "protocols bgp var neighbor var address-family ipv6-unicast nexthop-self" => "router bgp #3 ; address-family ipv6 ; neighbor #5 next-hop-self",
  "protocols bgp var neighbor var address-family ipv6-unicast prefix-list" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast prefix-list export" => "router bgp #3 ; address-family ipv6 ; neighbor #5 prefix-list #10 out",
  "protocols bgp var neighbor var address-family ipv6-unicast prefix-list import" => "router bgp #3 ; address-family ipv6 ; neighbor #5 prefix-list #10 in",
  "protocols bgp var neighbor var address-family ipv6-unicast remove-private-as" => "router bgp #3 ; address-family ipv6 ; neighbor #5 remove-private-AS",
  "protocols bgp var neighbor var address-family ipv6-unicast route-map" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast route-map export" => "router bgp #3 ; address-family ipv6 ; neighbor #5 route-map #10 out",
  "protocols bgp var neighbor var address-family ipv6-unicast route-map import" => "router bgp #3 ; address-family ipv6 ; neighbor #5 route-map #10 in",
  "protocols bgp var neighbor var address-family ipv6-unicast route-reflector-client" => "router bgp #3 ; address-family ipv6 ; neighbor #5 route-reflector-client",
  "protocols bgp var neighbor var address-family ipv6-unicast route-server-client" => "router bgp #3 ; address-family ipv6 ; neighbor #5 route-server-client",
  "protocols bgp var neighbor var address-family ipv6-unicast soft-reconfiguration" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast soft-reconfiguration inbound" => "router bgp #3 ; address-family ipv6 ; neighbor #5 soft-reconfiguration inbound",
  "protocols bgp var neighbor var address-family ipv6-unicast unsuppress-map" => "router bgp #3 ; address-family ipv6 ; neighbor #5 unsuppress-map #9",
  "protocols bgp var neighbor var advertisement-interval" => "router bgp #3 ; neighbor #5 advertisement-interval #7",
  # allowas-in as a standalone means any number of times.  append number and you will only accept local-as N number of times in as-path
  "protocols bgp var neighbor var allowas-in" => "router bgp #3 ; neighbor #5 allowas-in",
  # default is 3, default won't be shown in quagga
  "protocols bgp var neighbor var allowas-in number" => "router bgp #3 ; neighbor #5 allowas-in #8",
  # it looks like "attribute-unchanged" as a standalone is really "attribute-unchanged as-path med next-hop"
  "protocols bgp var neighbor var attribute-unchanged" => "router bgp #3 ; no neighbor #5 attribute-unchanged ; neighbor #5 attribute-unchanged ?as-path ?med ?next-hop",
  "protocols bgp var neighbor var capability" => undef,
  "protocols bgp var neighbor var capability dynamic" => "router bgp #3 ; neighbor #5 capability dynamic",
  "protocols bgp var neighbor var capability orf" => undef,
  "protocols bgp var neighbor var capability orf prefix-list" => undef,
  # if both send and receive are sent then this gets translated to both in Quagga config.  Doesn't mess up the delete though.
  "protocols bgp var neighbor var capability orf prefix-list receive" => "router bgp #3 ; neighbor #5 capability orf prefix-list receive",
  "protocols bgp var neighbor var capability orf prefix-list send" => "router bgp #3 ; neighbor #5 capability orf prefix-list send",
  "protocols bgp var neighbor var default-originate" => "router bgp #3 ; neighbor #5 default-originate",
  "protocols bgp var neighbor var default-originate route-map" => "router bgp #3 ; neighbor #5 default-originate route-map #8",
  "protocols bgp var neighbor var disable-capability-negotiation" => "router bgp #3 ; neighbor #5 dont-capability-negotiate",
  "protocols bgp var neighbor var disable-connected-check" => "router bgp #3 ; neighbor #5 disable-connected-check",
  "protocols bgp var neighbor var disable-send-community" => undef,
  "protocols bgp var neighbor var disable-send-community extended" => "router bgp #3 ; no neighbor #5 send-community extended",
  "protocols bgp var neighbor var disable-send-community standard" => "router bgp #3 ; no neighbor #5 send-community standard",
  "protocols bgp var neighbor var distribute-list" => undef,
  "protocols bgp var neighbor var distribute-list export" => "router bgp #3 ; neighbor #5 distribute-list #8 out",
  "protocols bgp var neighbor var distribute-list import" => "router bgp #3 ; neighbor #5 distribute-list #8 in",
  "protocols bgp var neighbor var ebgp-multihop" => "router bgp #3 ; neighbor #5 ebgp-multihop #7",
  "protocols bgp var neighbor var filter-list" => undef,
  "protocols bgp var neighbor var filter-list export" => "router bgp #3 ; neighbor #5 filter-list #8 out",
  "protocols bgp var neighbor var filter-list import" => "router bgp #3 ; neighbor #5 filter-list #8 in",
  "protocols bgp var neighbor var local-as" => undef,
  "protocols bgp var neighbor var local-as var" => "router bgp #3 ; no neighbor #5 local-as #7 ; neighbor #5 local-as #7",
  "protocols bgp var neighbor var local-as var no-prepend" => "router bgp #3 ; no neighbor #5 local-as #7 ; neighbor #5 local-as #7 no-prepend",
  "protocols bgp var neighbor var maximum-prefix" => "router bgp #3 ; neighbor #5 maximum-prefix #7",
  "protocols bgp var neighbor var nexthop-self" => "router bgp #3 ; neighbor #5 next-hop-self",
  "protocols bgp var neighbor var override-capability" => "router bgp #3 ; neighbor #5 override-capability",
  "protocols bgp var neighbor var passive" => "router bgp #3 ; neighbor #5 passive",
  "protocols bgp var neighbor var password" => "router bgp #3 ; neighbor #5 password #7",
  "protocols bgp var neighbor var peer-group" => "router bgp #3 ; neighbor #5 peer-group #7",
  "protocols bgp var neighbor var port" => "router bgp #3 ; neighbor #5 port #7",
  "protocols bgp var neighbor var prefix-list" => undef,
  "protocols bgp var neighbor var prefix-list export" => "router bgp #3 ; neighbor #5 prefix-list #8 out",
  "protocols bgp var neighbor var prefix-list import" => "router bgp #3 ; neighbor #5 prefix-list #8 in",
  "protocols bgp var neighbor var remote-as" => "router bgp #3 ; neighbor #5 remote-as #7",
  "protocols bgp var neighbor var remove-private-as" => "router bgp #3 ; neighbor #5 remove-private-AS",
  "protocols bgp var neighbor var route-map" => undef,
  "protocols bgp var neighbor var route-map export" => "router bgp #3 ; neighbor #5 route-map #8 out",
  "protocols bgp var neighbor var route-map import" => "router bgp #3 ; neighbor #5 route-map #8 in",
  "protocols bgp var neighbor var route-reflector-client" => "router bgp #3 ; neighbor #5 route-reflector-client",
  "protocols bgp var neighbor var route-server-client" => "router bgp #3 ; neighbor #5 route-server-client",
  "protocols bgp var neighbor var shutdown" => "router bgp #3 ; neighbor #5 shutdown",
  "protocols bgp var neighbor var soft-reconfiguration" => undef,
  "protocols bgp var neighbor var soft-reconfiguration inbound" => "router bgp #3 ; neighbor #5 soft-reconfiguration inbound",
  "protocols bgp var neighbor var strict-capability-match" => "router bgp #3 ; neighbor #5 strict-capability-match", 
  "protocols bgp var neighbor var timers" => 'router bgp #3 ; neighbor #5 timers @keepalive @holdtime',
  "protocols bgp var neighbor var timers connect" => "router bgp #3 ; neighbor #5 timers connect #8",
  "protocols bgp var neighbor var unsuppress-map" => "router bgp #3 ; neighbor #5 unsuppress-map #7",
  "protocols bgp var neighbor var update-source" => "router bgp #3 ; neighbor #5 update-source #7",
  "protocols bgp var neighbor var weight" => "router bgp #3 ; neighbor #5 weight #7",
  "protocols bgp var network" => undef,
  "protocols bgp var network var" => "router bgp #3 ; network #5 ?backdoor",
  "protocols bgp var network var route-map" => "router bgp #3 ; network #5 route-map #7",
  "protocols bgp var parameters" => undef,
  "protocols bgp var parameters always-compare-med" => "router bgp #3 ; bgp always-compare-med",
  "protocols bgp var parameters bestpath" => undef,
  "protocols bgp var parameters bestpath as-path" => undef,
  "protocols bgp var parameters bestpath as-path confed" => "router bgp #3 ; bgp bestpath as-path confed",
  "protocols bgp var parameters bestpath as-path ignore" => "router bgp #3 ; bgp bestpath as-path ignore",
  "protocols bgp var parameters bestpath compare-routerid" => "router bgp #3 ; bgp bestpath compare-routerid",
  "protocols bgp var parameters bestpath med" => undef,
  "protocols bgp var parameters bestpath med confed" => "router bgp #3 ; bgp bestpath med confed",
  "protocols bgp var parameters bestpath med missing-as-worst" => "router bgp #3 ; bgp bestpath med missing-as-worst",
  "protocols bgp var parameters cluster-id" => "router bgp #3 ; bgp cluster-id #6",
  "protocols bgp var parameters confederation" => undef,
  "protocols bgp var parameters confederation identifier" => "router bgp #3 ; bgp confederation identifier #7",
  "protocols bgp var parameters confederation peers" => "router bgp #3 ; bgp confederation peers #7",
  "protocols bgp var parameters dampening" => 'router bgp #3 ; no bgp dampening ; bgp dampening @half-life @re-use @start-suppress-time @max-suppress-time',
  "protocols bgp var parameters default" => undef,
  "protocols bgp var parameters default local-pref" => "router bgp #3 ; bgp default local-preference #7",
  "protocols bgp var parameters default no-ipv4-unicast" => "router bgp #3 ; no bgp default ipv4-unicast",
  "protocols bgp var parameters deterministic-med" => "router bgp #3 ; bgp deterministic-med",
  "protocols bgp var parameters disable-network-import-check" => "router bgp #3 ; no bgp network import-check",
  "protocols bgp var parameters enforce-first-as" => "router bgp #3 ; bgp enforce-first-as",
  "protocols bgp var parameters graceful-restart" => undef,
  "protocols bgp var parameters graceful-restart stalepath-time" => "router bgp #3 ; bgp graceful-restart stalepath-time #7",
  "protocols bgp var parameters log-neighbor-changes" => "router bgp #3 ; bgp log-neighbor-changes",
  "protocols bgp var parameters no-client-to-client-reflection" => "router bgp #3 ; no bgp client-to-client reflection",
  "protocols bgp var parameters no-fast-external-failover" => "router bgp #3 ; no bgp fast-external-failover",
  "protocols bgp var parameters router-id" => "router bgp #3 ; bgp router-id #6",
  "protocols bgp var parameters scan-time" => "router bgp #3 ; bgp scan-time #6",
  "protocols bgp var peer-group" => undef,
  "protocols bgp var peer-group var" => "router bgp #3 ; neighbor #5 peer-group",
  "protocols bgp var peer-group var address-family" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast allowas-in" => "router bgp #3 ; address-family ipv6 ; neighbor #5 allowas-in",
  "protocols bgp var peer-group var address-family ipv6-unicast attribute-unchanged" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 attribute-unchanged ; neighbor #5 attribute-unchanged ?as-path ?med ?next-hop",
  "protocols bgp var peer-group var address-family ipv6-unicast capability" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast capability dynamic" => "router bgp #3 ; address-family ipv6 ; neighbor #5 capability dynamic",
  "protocols bgp var peer-group var address-family ipv6-unicast capability orf" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast capability orf prefix-list" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast capability orf prefix-list receive" => "router bgp #3 ; address-family ipv6 ; neighbor #5 capability orf prefix-list receive",
  "protocols bgp var peer-group var address-family ipv6-unicast capability orf prefix-list send" => "router bgp #3 ; address-family ipv6 ; neighbor #5 capability orf prefix-list send",
  "protocols bgp var peer-group var address-family ipv6-unicast default-originate" => "router bgp #3 ; address-family ipv6 ; neighbor #5 default-originate",
  "protocols bgp var peer-group var address-family ipv6-unicast default-originate route-map" => "router bgp #3 ; address-family ipv6 ; neighbor #5 default-originate route-map #10",
  "protocols bgp var peer-group var address-family ipv6-unicast disable-send-community" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast disable-send-community extended" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 send-community extended",
  "protocols bgp var peer-group var address-family ipv6-unicast disable-send-community standard" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 send-community standard",
  "protocols bgp var peer-group var address-family ipv6-unicast distribute-list" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast distribute-list export" => "router bgp #3 ; address-family ipv6 ; neighbor #5 distribute-list #10 out",
  "protocols bgp var peer-group var address-family ipv6-unicast distribute-list import" => "router bgp #3 ; address-family ipv6 ; neighbor #5 distribute-list #10 in",
  "protocols bgp var peer-group var address-family ipv6-unicast filter-list" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast filter-list export" => "router bgp #3 ; address-family ipv6 ; neighbor #5 filter-list #10 out",
  "protocols bgp var peer-group var address-family ipv6-unicast filter-list import" => "router bgp #3 ; address-family ipv6 ; neighbor #5 filter-list #10 in",
  "protocols bgp var peer-group var address-family ipv6-unicast maximum-prefix" => "router bgp #3 ; address-family ipv6 ; neighbor #5 maximum-prefix #9",
  "protocols bgp var peer-group var address-family ipv6-unicast nexthop-local" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast nexthop-local" => "router bgp #3 ; address-family ipv6 ; neighbor #5 nexthop-local unchanged",
  "protocols bgp var peer-group var address-family ipv6-unicast nexthop-self" => "router bgp #3 ; address-family ipv6 ; neighbor #5 next-hop-self",
  "protocols bgp var peer-group var address-family ipv6-unicast prefix-list" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast prefix-list export" => "router bgp #3 ; address-family ipv6 ; neighbor #5 prefix-list #10 out",
  "protocols bgp var peer-group var address-family ipv6-unicast prefix-list import" => "router bgp #3 ; address-family ipv6 ; neighbor #5 prefix-list #10 in",
  "protocols bgp var peer-group var address-family ipv6-unicast remove-private-as" => "router bgp #3 ; address-family ipv6 ; neighbor #5 remove-private-AS",
  "protocols bgp var peer-group var address-family ipv6-unicast route-map" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast route-map export" => "router bgp #3 ; address-family ipv6 ; neighbor #5 route-map #10 out",
  "protocols bgp var peer-group var address-family ipv6-unicast route-map import" => "router bgp #3 ; address-family ipv6 ; neighbor #5 route-map #10 in",
  "protocols bgp var peer-group var address-family ipv6-unicast route-reflector-client" => "router bgp #3 ; address-family ipv6 ; neighbor #5 route-reflector-client",
  "protocols bgp var peer-group var address-family ipv6-unicast route-server-client" => "router bgp #3 ; address-family ipv6 ; neighbor #5 route-server-client",
  "protocols bgp var peer-group var address-family ipv6-unicast soft-reconfiguration" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast soft-reconfiguration inbound" => "router bgp #3 ; address-family ipv6 ; neighbor #5 soft-reconfiguration inbound",
  "protocols bgp var peer-group var address-family ipv6-unicast unsuppress-map" => "router bgp #3 ; address-family ipv6 ; neighbor #5 unsuppress-map #9",
  "protocols bgp var peer-group var allowas-in" => "router bgp #3 ; neighbor #5 allowas-in",
  "protocols bgp var peer-group var allowas-in number" => "router bgp #3 ; neighbor #5 allowas-in #8",
  "protocols bgp var peer-group var attribute-unchanged" => "router bgp #3 ; no neighbor #5 attribute-unchanged ; neighbor #5 attribute-unchanged ?as-path ?med ?next-hop",
  "protocols bgp var peer-group var capability" => undef,
  "protocols bgp var peer-group var capability dynamic" => "router bgp #3 ; neighbor #5 capability dynamic",
  "protocols bgp var peer-group var capability orf" => undef,
  "protocols bgp var peer-group var capability orf prefix-list" => undef,
  "protocols bgp var peer-group var capability orf prefix-list receive" => "router bgp #3 ; neighbor #5 capability orf prefix-list receive",
  "protocols bgp var peer-group var capability orf prefix-list send" => "router bgp #3 ; neighbor #5 capability orf prefix-list send",
  "protocols bgp var peer-group var default-originate" => "router bgp #3 ; neighbor #5 default-originate",
  "protocols bgp var peer-group var default-originate route-map" => "router bgp #3 ; neighbor #5 default-originate route-map #8",
  "protocols bgp var peer-group var disable-capability-negotiation" => "router bgp #3 ; neighbor #5 dont-capability-negotiate",
  "protocols bgp var peer-group var disable-connected-check" => "router bgp #3 ; neighbor #5 disable-connected-check",
  "protocols bgp var peer-group var disable-send-community" => undef,
  "protocols bgp var peer-group var disable-send-community extended" => "router bgp #3 ; no neighbor #5 send-community extended",
  "protocols bgp var peer-group var disable-send-community standard" => "router bgp #3 ; no neighbor #5 send-community standard",
  "protocols bgp var peer-group var distribute-list" => undef,
  "protocols bgp var peer-group var distribute-list export" => "router bgp #3 ; neighbor #5 distribute-list #8 out",
  "protocols bgp var peer-group var distribute-list import" => "router bgp #3 ; neighbor #5 distribute-list #8 in",
  "protocols bgp var peer-group var ebgp-multihop" => "router bgp #3 ; neighbor #5 ebgp-multihop #7",
  "protocols bgp var peer-group var filter-list" => undef,
  "protocols bgp var peer-group var filter-list export" => "router bgp #3 ; neighbor #5 filter-list #8 out",
  "protocols bgp var peer-group var filter-list import" => "router bgp #3 ; neighbor #5 filter-list #8 in",
  "protocols bgp var peer-group var local-as" => undef,
  "protocols bgp var peer-group var local-as var" => "router bgp #3 ; no neighbor #5 local-as #7 ; neighbor #5 local-as #7",
  "protocols bgp var peer-group var local-as var no-prepend" => "router bgp #3 ; no neighbor #5 local-as #7 ; neighbor #5 local-as #7 no-prepend",
  "protocols bgp var peer-group var maximum-prefix" => "router bgp #3 ; neighbor #5 maximum-prefix #7",
  "protocols bgp var peer-group var nexthop-self" => "router bgp #3 ; neighbor #5 next-hop-self",
  "protocols bgp var peer-group var override-capability" => "router bgp #3 ; neighbor #5 override-capability",
  "protocols bgp var peer-group var passive" => "router bgp #3 ; neighbor #5 passive",
  "protocols bgp var peer-group var password" => "router bgp #3 ; neighbor #5 password #7",
  "protocols bgp var peer-group var port" => "router bgp #3 ; neighbor #5 port #7",
  "protocols bgp var peer-group var prefix-list" => undef,
  "protocols bgp var peer-group var prefix-list export" => "router bgp #3 ; neighbor #5 prefix-list #8 out",
  "protocols bgp var peer-group var prefix-list import" => "router bgp #3 ; neighbor #5 prefix-list #8 in",
  "protocols bgp var peer-group var remote-as" => "router bgp #3 ; neighbor #5 peer-group ; neighbor #5 remote-as #7",
  "protocols bgp var peer-group var remove-private-as" => "router bgp #3 ; neighbor #5 remove-private-AS",
  "protocols bgp var peer-group var route-map" => undef,
  "protocols bgp var peer-group var route-map export" => "router bgp #3 ; neighbor #5 route-map #8 out",
  "protocols bgp var peer-group var route-map import" => "router bgp #3 ; neighbor #5 route-map #8 in",
  "protocols bgp var peer-group var route-reflector-client" => "router bgp #3 ; neighbor #5 route-reflector-client",
  "protocols bgp var peer-group var route-server-client" => "router bgp #3 ; neighbor #5 route-server-client",
  "protocols bgp var peer-group var shutdown" => "router bgp #3 ; neighbor #5 shutdown",
  "protocols bgp var peer-group var soft-reconfiguration" => undef,
  "protocols bgp var peer-group var soft-reconfiguration inbound" => "router bgp #3 ; neighbor #5 soft-reconfiguration inbound",
  "protocols bgp var peer-group var timers" => 'router bgp #3 ; neighbor #5 timers @keepalive @holdtime',
  "protocols bgp var peer-group var timers connect" => "router bgp #3 ; neighbor #5 timers connect #8",
  "protocols bgp var peer-group var unsuppress-map" => "router bgp #3 ; neighbor #5 unsuppress-map #7",
  "protocols bgp var peer-group var update-source" => "router bgp #3 ; neighbor #5 update-source #7",
  "protocols bgp var peer-group var weight" => "router bgp #3 ; neighbor #5 weight #7",
  "protocols bgp var redistribute" => undef,
  "protocols bgp var redistribute connected" => "router bgp #3 ; redistribute connected",
  "protocols bgp var redistribute connected metric" => "router bgp #3 ; redistribute connected metric #7",
  "protocols bgp var redistribute connected route-map" => "router bgp #3 ; redistribute connected route-map #7",
  "protocols bgp var redistribute kernel" => "router bgp #3 ; redistribute kernel",
  "protocols bgp var redistribute kernel metric" => "router bgp #3 ; redistribute kernel metric #7",
  "protocols bgp var redistribute kernel route-map" => "router bgp #3 ; redistribute kernel route-map #7",
  "protocols bgp var redistribute ospf" => "router bgp #3 ; redistribute ospf",
  "protocols bgp var redistribute ospf metric" => "router bgp #3 ; redistribute ospf metric #7",
  "protocols bgp var redistribute ospf route-map" => "router bgp #3 ; redistribute ospf route-map #7",
  "protocols bgp var redistribute rip" => "router bgp #3 ; redistribute rip",
  "protocols bgp var redistribute rip metric" => "router bgp #3 ; redistribute rip metric #7",
  "protocols bgp var redistribute rip route-map" => "router bgp #3 ; redistribute rip route-map #7",
  "protocols bgp var redistribute static" => "router bgp #3 ; redistribute static",
  "protocols bgp var redistribute static metric" => "router bgp #3 ; redistribute static metric #7",
  "protocols bgp var redistribute static route-map" => "router bgp #3 ; redistribute static route-map #7",
  "protocols bgp var timers" => 'router bgp #3 ; timers bgp @keepalive @holdtime',
);

my %qcomdel = (
  "protocols" => undef,
  "protocols bgp" => undef,
  "protocols bgp var" => "no router bgp #3",
  "protocols bgp var aggregate-address" => undef,
  "protocols bgp var aggregate-address var" => "router bgp #3 ; no aggregate-address #5 ?as-set ?summary-only",
  "protocols bgp var address-family" => undef,
  "protocols bgp var address-family ipv6-unicast" => undef,
  "protocols bgp var address-family ipv6-unicast aggregate-address" => undef,
  "protocols bgp var address-family ipv6-unicast aggregate-address var" => "router bgp #3 ; no ipv6 bgp aggregate-address #7",
  "protocols bgp var address-family ipv6-unicast network" => "router bgp #3 ; no ipv6 bgp network #7 ; no ipv6 bgp network #7",
  "protocols bgp var address-family ipv6-unicast redistribute" => undef,
  "protocols bgp var address-family ipv6-unicast redistribute connected" => "router bgp #3 ; address-family ipv6 ; no redistribute connected",
  "protocols bgp var address-family ipv6-unicast redistribute connected metric" => "router bgp #3 ; address-family ipv6 ; no redistribute connected metric #9",
  "protocols bgp var address-family ipv6-unicast redistribute connected route-map" => "router bgp #3 ; address-family ipv6 ; no redistribute connected route-map #9",
  "protocols bgp var address-family ipv6-unicast redistribute kernel" => "router bgp #3 ; address-family ipv6 ; no redistribute kernel",
  "protocols bgp var address-family ipv6-unicast redistribute kernel metric" => "router bgp #3 ; address-family ipv6 ; no redistribute kernel metric #9",
  "protocols bgp var address-family ipv6-unicast redistribute kernel route-map" => "router bgp #3 ; address-family ipv6 ; no redistribute kernel route-map #9",
  "protocols bgp var address-family ipv6-unicast redistribute ospfv3" => "router bgp #3 ; address-family ipv6 ; no redistribute ospfv3",
  "protocols bgp var address-family ipv6-unicast redistribute ospfv3 metric" => "router bgp #3 ; address-family ipv6 ; no redistribute ospfv3 metric #9",
  "protocols bgp var address-family ipv6-unicast redistribute ospfv3 route-map" => "router bgp #3 ; address-family ipv6 ; no redistribute ospfv3 route-map #9",
  "protocols bgp var address-family ipv6-unicast redistribute ripng" => "router bgp #3 ; address-family ipv6 ; no redistribute ripng",
  "protocols bgp var address-family ipv6-unicast redistribute ripng metric" => "router bgp #3 ; address-family ipv6 ; no redistribute ripng metric #9",
  "protocols bgp var address-family ipv6-unicast redistribute ripng route-map" => "router bgp #3 ; address-family ipv6 ; no redistribute ripng route-map #9",
  "protocols bgp var address-family ipv6-unicast redistribute static" => "router bgp #3 ; address-family ipv6 ; no redistribute static",
  "protocols bgp var address-family ipv6-unicast redistribute static metric" => "router bgp #3 ; address-family ipv6 ; no redistribute static metric #9",
  "protocols bgp var address-family ipv6-unicast redistribute static route-map" => "router bgp #3 ; address-family ipv6 ; no redistribute static route-map #9",
  "protocols bgp var neighbor" => undef,
  "protocols bgp var neighbor var" => "router bgp #3 ; no neighbor #5",
  "protocols bgp var neighbor var address-family" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast" =>  "router bgp #3 ; address-family ipv6 ; no neighbor #5 activate",
  "protocols bgp var neighbor var address-family ipv6-unicast allowas-in" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 allowas-in",
  "protocols bgp var neighbor var address-family ipv6-unicast attribute-unchanged" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 attribute-unchanged",
  "protocols bgp var neighbor var address-family ipv6-unicast capability" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast capability dynamic" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 capability dynamic",
  "protocols bgp var neighbor var address-family ipv6-unicast capability orf" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast capability orf prefix-list" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast capability orf prefix-list receive" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 capability orf prefix-list receive",
  "protocols bgp var neighbor var address-family ipv6-unicast capability orf prefix-list send" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 capability orf prefix-list send",
  "protocols bgp var neighbor var address-family ipv6-unicast default-originate" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 default-originate",
  "protocols bgp var neighbor var address-family ipv6-unicast default-originate route-map" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 default-originate route-map #10",
  "protocols bgp var neighbor var address-family ipv6-unicast disable-send-community" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast disable-send-community extended" => "router bgp #3 ; address-family ipv6 ; neighbor #5 send-community extended",
  "protocols bgp var neighbor var address-family ipv6-unicast disable-send-community standard" => "router bgp #3 ; address-family ipv6 ; neighbor #5 send-community standard",
  "protocols bgp var neighbor var address-family ipv6-unicast distribute-list" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast distribute-list export" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 distribute-list #10 out",
  "protocols bgp var neighbor var address-family ipv6-unicast distribute-list import" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 distribute-list #10 in",
  "protocols bgp var neighbor var address-family ipv6-unicast filter-list" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast filter-list export" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 filter-list #10 out",
  "protocols bgp var neighbor var address-family ipv6-unicast filter-list import" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 filter-list #10 in",
  "protocols bgp var neighbor var address-family ipv6-unicast maximum-prefix" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 maximum-prefix #9",
  "protocols bgp var neighbor var address-family ipv6-unicast nexthop-local" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast nexthop-local" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 nexthop-local unchanged",
  "protocols bgp var neighbor var address-family ipv6-unicast nexthop-self" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 next-hop-self",
  "protocols bgp var neighbor var address-family ipv6-unicast prefix-list" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast prefix-list export" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 prefix-list #10 out",
  "protocols bgp var neighbor var address-family ipv6-unicast prefix-list import" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 prefix-list #10 in",
  "protocols bgp var neighbor var address-family ipv6-unicast remove-private-as" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 remove-private-AS",
  "protocols bgp var neighbor var address-family ipv6-unicast route-map" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast route-map export" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 route-map #10 out",
  "protocols bgp var neighbor var address-family ipv6-unicast route-map import" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 route-map #10 in",
  "protocols bgp var neighbor var address-family ipv6-unicast route-reflector-client" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 route-reflector-client",
  "protocols bgp var neighbor var address-family ipv6-unicast route-server-client" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 route-server-client",
  "protocols bgp var neighbor var address-family ipv6-unicast soft-reconfiguration" => undef,
  "protocols bgp var neighbor var address-family ipv6-unicast soft-reconfiguration inbound" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 soft-reconfiguration inbound",
  "protocols bgp var neighbor var address-family ipv6-unicast unsuppress-map" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 unsuppress-map #9",
  "protocols bgp var neighbor var advertisement-interval" => "router bgp #3 ; no neighbor #5 advertisement-interval",
  "protocols bgp var neighbor var allowas-in" => "router bgp #3 ; no neighbor #5 allowas-in",
  "protocols bgp var neighbor var allowas-in number" => "router bgp #3 ; no neighbor #5 allowas-in #8 ; neighbor #5 allowas-in",
  "protocols bgp var neighbor var attribute-unchanged" => "router bgp #3 ; no neighbor #5 attribute-unchanged ?as-path ?med ?next-hop",
  "protocols bgp var neighbor var capability" => undef,
  "protocols bgp var neighbor var capability dynamic" => "router bgp #3 ; no neighbor #5 capability dynamic",
  "protocols bgp var neighbor var capability orf" => undef,
  "protocols bgp var neighbor var capability orf prefix-list" => undef,
  "protocols bgp var neighbor var capability orf prefix-list receive" => "router bgp #3 ; no neighbor #5 capability orf prefix-list receive",
  "protocols bgp var neighbor var capability orf prefix-list send" => "router bgp #3 ; no neighbor #5 capability orf prefix-list send",
  "protocols bgp var neighbor var default-originate" => "router bgp #3 ; no neighbor #5 default-originate",
  "protocols bgp var neighbor var default-originate route-map" => "router bgp #3 ; no neighbor #5 default-originate route-map #8",
  "protocols bgp var neighbor var disable-capability-negotiation" => "router bgp #3 ; no neighbor #5 dont-capability-negotiate",
  "protocols bgp var neighbor var disable-connected-check" => "router bgp #3 ; no neighbor #5 disable-connected-check",
  "protocols bgp var neighbor var disable-send-community" => undef,
  "protocols bgp var neighbor var disable-send-community extended" => "router bgp #3 ; neighbor #5 send-community extended",
  "protocols bgp var neighbor var disable-send-community standard" => "router bgp #3 ; neighbor #5 send-community standard",
  "protocols bgp var neighbor var distribute-list" => undef,
  "protocols bgp var neighbor var distribute-list export" => "router bgp #3 ; no neighbor #5 distribute-list #8 out",
  "protocols bgp var neighbor var distribute-list import" => "router bgp #3 ; no neighbor #5 distribute-list #8 in",
  "protocols bgp var neighbor var ebgp-multihop" => "router bgp #3 ; no neighbor #5 ebgp-multihop",
  "protocols bgp var neighbor var filter-list" => undef,
  "protocols bgp var neighbor var filter-list export" => "router bgp #3 ; no neighbor #5 filter-list #8 out",
  "protocols bgp var neighbor var filter-list import" => "router bgp #3 ; no neighbor #5 filter-list #8 in",
  "protocols bgp var neighbor var local-as" => "router bgp #3 ; no neighbor #5 local-as",
  "protocols bgp var neighbor var local-as no-prepend" => "router bgp #3 ; no neighbor #5 local-as #7 no-prepend ; neighbor #5 local-as #7",
  "protocols bgp var neighbor var maximum-prefix" => "router bgp #3 ; no neighbor #5 maximum-prefix",
  "protocols bgp var neighbor var nexthop-self" => "router bgp #3 ; no neighbor #5 next-hop-self",
  "protocols bgp var neighbor var override-capability" => "router bgp #3 ; no neighbor #5 override-capability",
  "protocols bgp var neighbor var passive" => "router bgp #3 ; no neighbor #5 passive",
  "protocols bgp var neighbor var password" => "router bgp #3 ; no neighbor #5 password",
  "protocols bgp var neighbor var peer-group" => "router bgp #3 ; no neighbor #5 peer-group #7",
  "protocols bgp var neighbor var port" => "router bgp #3 ; no neighbor #5 port",
  "protocols bgp var neighbor var prefix-list" => undef,
  "protocols bgp var neighbor var prefix-list export" => "router bgp #3 ; no neighbor #5 prefix-list #8 out",
  "protocols bgp var neighbor var prefix-list import" => "router bgp #3 ; no neighbor #5 prefix-list #8 in",
  "protocols bgp var neighbor var remote-as" => "router bgp #3 ; no neighbor #5 remote-as #7",
  "protocols bgp var neighbor var remove-private-as" => "router bgp #3 ; no neighbor #5 remove-private-AS",
  "protocols bgp var neighbor var route-map" => undef,
  "protocols bgp var neighbor var route-map export" => "router bgp #3 ; no neighbor #5 route-map #8 out",
  "protocols bgp var neighbor var route-map import" => "router bgp #3 ; no neighbor #5 route-map #8 in",
  "protocols bgp var neighbor var route-reflector-client" => "router bgp #3 ; no neighbor #5 route-reflector-client",
  "protocols bgp var neighbor var route-server-client" => "router bgp #3 ; no neighbor #5 route-server-client",
  "protocols bgp var neighbor var shutdown" => "router bgp #3 ; no neighbor #5 shutdown",
  "protocols bgp var neighbor var soft-reconfiguration" => undef,
  "protocols bgp var neighbor var soft-reconfiguration inbound" => "router bgp #3 ; no neighbor #5 soft-reconfiguration inbound",
  "protocols bgp var neighbor var strict-capability-match" => "router bgp #3 ; no neighbor #5 strict-capability-match",
  "protocols bgp var neighbor var timers" => 'router bgp #3 ; no neighbor #5 timers',
  "protocols bgp var neighbor var timers connect" => "router bgp #3 ; no neighbor #5 timers connect",
  "protocols bgp var neighbor var unsuppress-map" => "router bgp #3 ; no neighbor #5 unsuppress-map #7",
  "protocols bgp var neighbor var update-source" => "router bgp #3 ; no neighbor #5 update-source",
  "protocols bgp var neighbor var weight" => "router bgp #3 ; no neighbor #5 weight",
  "protocols bgp var network" => undef,
  "protocols bgp var network var" => "router bgp #3 ; no network #5",
  "protocols bgp var network var route-map" => "router bgp #3 ; no network #5 route-map #7",
  "protocols bgp var parameters" => undef,
  "protocols bgp var parameters always-compare-med" => "router bgp #3 ; no bgp always-compare-med",
  "protocols bgp var parameters bestpath" => undef,
  "protocols bgp var parameters bestpath as-path" => undef,
  "protocols bgp var parameters bestpath as-path confed" => "router bgp #3 ; no bgp bestpath as-path confed",
  "protocols bgp var parameters bestpath as-path ignore" => "router bgp #3 ; no bgp bestpath as-path ignore",
  "protocols bgp var parameters bestpath compare-routerid" => "router bgp #3 ; no bgp bestpath compare-routerid",
  "protocols bgp var parameters bestpath med" => undef,
  "protocols bgp var parameters bestpath med confed" => "router bgp #3 ; no bgp bestpath med confed",
  "protocols bgp var parameters bestpath med missing-as-worst" => "router bgp #3 ; no bgp bestpath med missing-as-worst",
  "protocols bgp var parameters cluster-id" => "router bgp #3 ; no bgp cluster-id #6",
  "protocols bgp var parameters confederation" => undef,
  "protocols bgp var parameters confederation identifier" => "router bgp #3 ; no bgp confederation identifier #7",
  "protocols bgp var parameters confederation peers" => "router bgp #3 ; no bgp confederation peers #7",
  "protocols bgp var parameters dampening" => "router bgp #3 ; no bgp dampening",
  "protocols bgp var parameters default" => undef,
  "protocols bgp var parameters default local-pref" => "router bgp #3 ; no bgp default local-preference #7",
  "protocols bgp var parameters default no-ipv4-unicast" => "router bgp #3 ; bgp default ipv4-unicast",
  "protocols bgp var parameters deterministic-med" => "router bgp #3 ; no bgp deterministic-med",
  "protocols bgp var parameters disable-network-import-check" => "router bgp #3 ; bgp network import-check",
  "protocols bgp var parameters enforce-first-as" => "router bgp #3 ; no bgp enforce-first-as",
  "protocols bgp var parameters graceful-restart" => undef,
  "protocols bgp var parameters graceful-restart stalepath-time" => "router bgp #3 ; no bgp graceful-restart stalepath-time #7",
  "protocols bgp var parameters log-neighbor-changes" => "router bgp #3 ; no bgp log-neighbor-changes",
  "protocols bgp var parameters no-client-to-client-reflection" => "router bgp #3 ; bgp client-to-client reflection",
  "protocols bgp var parameters no-fast-external-failover" => "router bgp #3 ; bgp fast-external-failover",
  "protocols bgp var parameters router-id" => "router bgp #3 ; no bgp router-id #6",
  "protocols bgp var parameters scan-time" => "router bgp #3 ; no bgp scan-time #6",
  "protocols bgp var peer-group" => undef,
  "protocols bgp var peer-group var" => "router bgp #3 ; no neighbor #5 peer-group",
  "protocols bgp var peer-group var address-family" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast allowas-in" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 allowas-in",
  "protocols bgp var peer-group var address-family ipv6-unicast attribute-unchanged" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 attribute-unchanged",
  "protocols bgp var peer-group var address-family ipv6-unicast capability" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast capability dynamic" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 capability dynamic",
  "protocols bgp var peer-group var address-family ipv6-unicast capability orf" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast capability orf prefix-list" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast capability orf prefix-list receive" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 capability orf prefix-list receive",
  "protocols bgp var peer-group var address-family ipv6-unicast capability orf prefix-list send" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 capability orf prefix-list send",
  "protocols bgp var peer-group var address-family ipv6-unicast default-originate" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 default-originate",
  "protocols bgp var peer-group var address-family ipv6-unicast default-originate route-map" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 default-originate route-map #10",
  "protocols bgp var peer-group var address-family ipv6-unicast disable-send-community" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast disable-send-community extended" => "router bgp #3 ; address-family ipv6 ; neighbor #5 send-community extended",
  "protocols bgp var peer-group var address-family ipv6-unicast disable-send-community standard" => "router bgp #3 ; address-family ipv6 ; neighbor #5 send-community standard",
  "protocols bgp var peer-group var address-family ipv6-unicast distribute-list" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast distribute-list export" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 distribute-list #10 out",
  "protocols bgp var peer-group var address-family ipv6-unicast distribute-list import" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 distribute-list #10 in",
  "protocols bgp var peer-group var address-family ipv6-unicast filter-list" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast filter-list export" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 filter-list #10 out",
  "protocols bgp var peer-group var address-family ipv6-unicast filter-list import" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 filter-list #10 in",
  "protocols bgp var peer-group var address-family ipv6-unicast maximum-prefix" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 maximum-prefix #9",
  "protocols bgp var peer-group var address-family ipv6-unicast nexthop-local" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast nexthop-local" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 nexthop-local unchanged",
  "protocols bgp var peer-group var address-family ipv6-unicast nexthop-self" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 next-hop-self",
  "protocols bgp var peer-group var address-family ipv6-unicast prefix-list" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast prefix-list export" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 prefix-list #10 out",
  "protocols bgp var peer-group var address-family ipv6-unicast prefix-list import" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 prefix-list #10 in",
  "protocols bgp var peer-group var address-family ipv6-unicast remove-private-as" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 remove-private-AS",
  "protocols bgp var peer-group var address-family ipv6-unicast route-map" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast route-map export" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 route-map #10 out",
  "protocols bgp var peer-group var address-family ipv6-unicast route-map import" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 route-map #10 in",
  "protocols bgp var peer-group var address-family ipv6-unicast route-reflector-client" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 route-reflector-client",
  "protocols bgp var peer-group var address-family ipv6-unicast route-server-client" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 route-server-client",
  "protocols bgp var peer-group var address-family ipv6-unicast soft-reconfiguration" => undef,
  "protocols bgp var peer-group var address-family ipv6-unicast soft-reconfiguration inbound" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 soft-reconfiguration inbound",
  "protocols bgp var peer-group var address-family ipv6-unicast unsuppress-map" => "router bgp #3 ; address-family ipv6 ; no neighbor #5 unsuppress-map #9",
  "protocols bgp var peer-group var allowas-in" => "router bgp #3 ; no neighbor #5 allowas-in",
  "protocols bgp var peer-group var allowas-in number" => "router bgp #3 ; no neighbor #5 allowas-in #8 ; neighbor #5 allowas-in",
  "protocols bgp var peer-group var attribute-unchanged" => "router bgp #3 ; no neighbor #5 attribute-unchanged ?as-path ?med ?next-hop",
  "protocols bgp var peer-group var capability" => undef,
  "protocols bgp var peer-group var capability dynamic" => "router bgp #3 ; no neighbor #5 capability dynamic",
  "protocols bgp var peer-group var capability orf" => undef,
  "protocols bgp var peer-group var capability orf prefix-list" => undef,
  "protocols bgp var peer-group var capability orf prefix-list receive" => "router bgp #3 ; no neighbor #5 capability orf prefix-list receive",
  "protocols bgp var peer-group var capability orf prefix-list send" => "router bgp #3 ; no neighbor #5 capability orf prefix-list send",
  "protocols bgp var peer-group var default-originate" => "router bgp #3 ; no neighbor #5 default-originate",
  "protocols bgp var peer-group var default-originate route-map" => "router bgp #3 ; no neighbor #5 default-originate route-map #8",
  "protocols bgp var peer-group var disable-capability-negotiation" => "router bgp #3 ; no neighbor #5 dont-capability-negotiate",
  "protocols bgp var peer-group var disable-connected-check" => "router bgp #3 ; no neighbor #5 disable-connected-check",
  "protocols bgp var peer-group var disable-send-community" => undef,
  "protocols bgp var peer-group var disable-send-community extended" => "router bgp #3 ; neighbor #5 send-community extended",
  "protocols bgp var peer-group var disable-send-community standard" => "router bgp #3 ; neighbor #5 send-community standard",
  "protocols bgp var peer-group var distribute-list" => undef,
  "protocols bgp var peer-group var distribute-list export" => "router bgp #3 ; no neighbor #5 distribute-list #8 out",
  "protocols bgp var peer-group var distribute-list import" => "router bgp #3 ; no neighbor #5 distribute-list #8 in",
  "protocols bgp var peer-group var ebgp-multihop" => "router bgp #3 ; no neighbor #5 ebgp-multihop #7",
  "protocols bgp var peer-group var filter-list" => undef,
  "protocols bgp var peer-group var filter-list export" => "router bgp #3 ; no neighbor #5 filter-list #8 out",
  "protocols bgp var peer-group var filter-list import" => "router bgp #3 ; no neighbor #5 filter-list #8 in",
  "protocols bgp var peer-group var local-as" => undef,
  "protocols bgp var peer-group var local-as var" => "router bgp #3 ; no neighbor #5 local-as #7",
  "protocols bgp var peer-group var local-as var no-prepend" => "router bgp #3 ; no neighbor #5 local-as #7 ; neighbor #5 local-as",
  "protocols bgp var peer-group var maximum-prefix" => "router bgp #3 ; no neighbor #5 maximum-prefix #7",
  "protocols bgp var peer-group var nexthop-self" => "router bgp #3 ; no neighbor #5 next-hop-self",
  "protocols bgp var peer-group var override-capability" => "router bgp #3 ; no neighbor #5 override-capability",
  "protocols bgp var peer-group var passive" => "router bgp #3 ; no neighbor #5 passive",
  "protocols bgp var peer-group var password" => "router bgp #3 ; no neighbor #5 password #7",
  "protocols bgp var peer-group var port" => "router bgp #3 ; no neighbor #5 port #7",
  "protocols bgp var peer-group var prefix-list" => undef,
  "protocols bgp var peer-group var prefix-list export" => "router bgp #3 ; no neighbor #5 prefix-list #8 out",
  "protocols bgp var peer-group var prefix-list import" => "router bgp #3 ; no neighbor #5 prefix-list #8 in",
  "protocols bgp var peer-group var remote-as" => "router bgp #3 ; no neighbor #5",
  "protocols bgp var peer-group var remove-private-as" => "router bgp #3 ; no neighbor #5 remove-private-AS",
  "protocols bgp var peer-group var route-map" => undef,
  "protocols bgp var peer-group var route-map export" => "router bgp #3 ; no neighbor #5 route-map #8 out",
  "protocols bgp var peer-group var route-map import" => "router bgp #3 ; no neighbor #5 route-map #8 in",
  "protocols bgp var peer-group var route-reflector-client" => "router bgp #3 ; no neighbor #5 route-reflector-client",
  "protocols bgp var peer-group var route-server-client" => "router bgp #3 ; no neighbor #5 route-server-client",
  "protocols bgp var peer-group var shutdown" => "router bgp #3 ; no neighbor #5 shutdown",
  "protocols bgp var peer-group var soft-reconfiguration" => undef,
  "protocols bgp var peer-group var soft-reconfiguration inbound" => "router bgp #3 ; no neighbor #5 soft-reconfiguration inbound",
  "protocols bgp var peer-group var timers" => "router bgp #3 ; no neighbor #5",
  "protocols bgp var peer-group var timers connect" => "router bgp #3 ; no neighbor #5 timers connect #8",
  "protocols bgp var peer-group var unsuppress-map" => "router bgp #3 ; no neighbor #5 unsuppress-map #7",
  "protocols bgp var peer-group var update-source" => "router bgp #3 ; no neighbor #5 update-source #7",
  "protocols bgp var peer-group var weight" => "router bgp #3 ; no neighbor #5 weight #7",
  "protocols bgp var redistribute" => undef,
  "protocols bgp var redistribute connected" => "router bgp #3 ; no redistribute connected",
  "protocols bgp var redistribute connected metric" => "router bgp #3 ; no redistribute connected metric #7",
  "protocols bgp var redistribute connected route-map" => "router bgp #3 ; no redistribute connected route-map #7",
  "protocols bgp var redistribute kernel" => "router bgp #3 ; no redistribute kernel",
  "protocols bgp var redistribute kernel metric" => "router bgp #3 ; no redistribute kernel metric #7",
  "protocols bgp var redistribute kernel route-map" => "router bgp #3 ; no redistribute kernel route-map #7",
  "protocols bgp var redistribute ospf" => "router bgp #3 ; no redistribute ospf",
  "protocols bgp var redistribute ospf metric" => "router bgp #3 ; no redistribute ospf metric #7",
  "protocols bgp var redistribute ospf route-map" => "router bgp #3 ; no redistribute ospf route-map #7",
  "protocols bgp var redistribute rip" => "router bgp #3 ; no redistribute rip",
  "protocols bgp var redistribute rip metric" => "router bgp #3 ; no redistribute rip metric #7",
  "protocols bgp var redistribute rip route-map" => "router bgp #3 ; no redistribute rip route-map #7",
  "protocols bgp var redistribute static" => "router bgp #3 ; no redistribute static",
  "protocols bgp var redistribute static metric" => "router bgp #3 ; no redistribute static metric #7",
  "protocols bgp var redistribute static route-map" => "router bgp #3 ; no redistribute static route-map #7",
  "protocols bgp var timers" => "router bgp #3 ; no timers bgp",
);

my ( $pg, $as, $neighbor );
my ( $main, $checkas, $peername, $isneighbor, $checkpeergroupas, $checkpeergroups, $checksource );

GetOptions(
    "peergroup=s"             => \$pg,
    "as=s"                    => \$as,
    "neighbor=s"              => \$neighbor,
    "check-peergroup-name=s"  => \$peername,
    "check-neighbor-ip"       => \$isneighbor,
    "check-as"                => \$checkas,
    "check-peergroup-as"      => \$checkpeergroupas,
    "check-peer-groups"       => \$checkpeergroups,
    "check-source=s"	      => \$checksource,
    "main"                    => \$main,
);

main()					if ($main);
check_peergroup_name($peername)	  	if ($peername);
check_neighbor_ip($neighbor)            if ($isneighbor);
check_for_peer_groups( $pg, $as )	if ($checkpeergroups);
check_neighbor_as( $neighbor, $as) 	if ($checkas);
check_peergroup_as( $neighbor, $as)     if ($checkpeergroupas);
check_source($checksource)	        if ($checksource);

exit 0;

# Make sure the peer IP is properly formatted
sub check_neighbor_ip {
    my $neighbor = shift;

    exit 1 if ! is_ip_v4_or_v6($neighbor);
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
# neighbors configured to us it
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
        if ( $peergroup eq $pg ) { push @peers, $node; }
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

# make sure nodes are either in a peer group or have
# a remote AS assigned to them.
sub check_neighbor_as {
    my ($neighbor, $as) = @_;

    die "neighbor not defined\n" unless $neighbor;
    die "AS not defined\n" unless $as;

    my $config = new Vyatta::Config;
    $config->setLevel("protocols bgp $as neighbor $neighbor");
    my $remoteas = $config->returnValue("remote-as");
    return if defined $remoteas;

    my $peergroup   = $config->returnValue("peer-group");
    die "protocols bgp $as neighbor $neighbor: must define a remote-as or peer-group\n"
      unless $peergroup;

    my $peergroupas = $config->returnValue(" .. .. peer-group $peergroup remote-as");
    die "protocols bgp $as neighbor $neighbor: must define a remote-as in neighbor or peer-group $peergroup\n"
      unless $peergroupas;
}

# make sure peer-group has a remote-as
sub check_peergroup_as {
    my ($neighbor, $as) = @_;

    die "neighbor not defined\n" unless $neighbor;
    die "AS not defined\n" unless $as;

    my $config = new Vyatta::Config;
    $config->setLevel("protocols bgp $as peer-group $neighbor");
    my $remoteas = $config->returnValue("remote-as");
    return if defined $remoteas;
    die "protocols bgp $as peer-group $neighbor: must define a remote-as\n";
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

sub main {
   # initialize the Quagga Config object with data from Vyatta config tree
   my $qconfig = new Vyatta::Quagga::Config('protocols', \%qcom, \%qcomdel);

   #$qconfig->setDebugLevel('3');
   #$qconfig->_reInitialize();

   # deletes with priority
   $qconfig->deleteConfigTreeRecursive('protocols bgp') || die "exiting $?\n";
   # would be cool if I could add a recursive delete such as everything but (protocols bgp var neigh var remote-as)

   # sets with priority
   $qconfig->setConfigTreeRecursive('protocols bgp var parameters') || die "exiting $?\n";
   $qconfig->setConfigTree('protocols bgp var peer-group var remote-as') || die "exiting $?\n";
   $qconfig->setConfigTreeRecursive('protocols bgp var peer-group') || die "exiting $?\n";
   $qconfig->setConfigTree('protocols bgp var neighbor var remote-as') || die "exiting $?\n";
   $qconfig->setConfigTree('protocols bgp var neighbor var shutdown') || die "exiting $?\n";
   $qconfig->setConfigTreeRecursive('protocols bgp var neighbor var route-map') || die "exiting $?\n";
   $qconfig->setConfigTreeRecursive('protocols bgp var neighbor var filter-list') || die "exiting $?\n";
   $qconfig->setConfigTreeRecursive('protocols bgp var neighbor var prefix-list') || die "exiting $?\n";
   $qconfig->setConfigTreeRecursive('protocols bgp var neighbor var distribute-list') || die "exiting $?\n";
   $qconfig->setConfigTreeRecursive('protocols bgp var neighbor var unsuppress-map') || die "exiting $?\n";
   $qconfig->setConfigTreeRecursive('protocols bgp var neighbor') || die "exiting $?\n";
   $qconfig->setConfigTreeRecursive('protocols bgp') || die "exiting $?\n";

   #705 protocols bgp var neighbhor shutdown
   #715 protocols bgp var neighbhor route-map
   #716 protocols bgp var neighbhor filter-list
   #717 protocols bgp var neighbhor prefix-list
   #718 protocols bgp var neighbhor distribute-list
   #719 protocols bgp var neighbhor unsuppress-map
   #720 protocols bgp var neighbhor
   #730 protocols bgp var
}

