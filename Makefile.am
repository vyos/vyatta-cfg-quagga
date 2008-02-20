cfgdir = $(datadir)/vyatta-cfg/templates

sbin_SCRIPTS = scripts/bgp/vyatta-bgp.pl
sbin_SCRIPTS += scripts/policy/vyatta-policy.pl
sbin_SCRIPTS += scripts/vyatta_quagga_utils.pl
sbin_SCRIPTS += scripts/policy/vyatta-check-as-prepend.pl
sbin_SCRIPTS += scripts/vyatta-vtysh.pl
sbin_SCRIPTS += scripts/vyatta-linkstatus.pl
sbin_SCRIPTS += scripts/vyatta-policy-action-verify.pl

cpiop = find  . ! -regex '\(.*~\|.*\.bak\|.*\.swp\|.*\#.*\#\)' -print0 | \
	cpio -0pd

install-exec-hook:
	mkdir -p $(DESTDIR)$(cfgdir)
	cd templates; $(cpiop) $(DESTDIR)$(cfgdir)
