cfgdir = $(datadir)/vyatta-cfg/templates
curverdir = $(sysconfdir)/config-migrate/current

sbin_SCRIPTS = scripts/bgp/vyatta-bgp.pl
sbin_SCRIPTS += scripts/policy/vyatta-policy.pl
sbin_SCRIPTS += scripts/vyatta_quagga_utils.pl
sbin_SCRIPTS += scripts/policy/vyatta-check-as-prepend.pl
sbin_SCRIPTS += scripts/vyatta-policy-action-verify.pl
sbin_SCRIPTS += scripts/vyatta-gateway-static_route-check.pl
sbin_SCRIPTS += scripts/vyatta-link-detect

sbin_PROGRAMS = src/check_prefix_boundary

src_check_prefix_boundary = src/check_prefix_boundary.c

curver_DATA = cfg-version/quagga@1

cpiop = find  . ! -regex '\(.*~\|.*\.bak\|.*\.swp\|.*\#.*\#\)' -print0 | \
	cpio -0pd

install-exec-hook:
	mkdir -p $(DESTDIR)$(cfgdir)
	cd templates; $(cpiop) $(DESTDIR)$(cfgdir)
