cfgdir = $(datadir)/vyatta-cfg/templates

sbin_SCRIPTS = scripts/bgp/vyatta-bgp.pl
sbin_SCRIPTS += scripts/policy/vyatta-policy.pl

cpiop = find  . ! -regex '\(.*~\|.*\.bak\|.*\.swp\|.*\#.*\#\)' -print0 | \
	cpio -0pd

install-exec-hook:
	mkdir -p $(DESTDIR)$(cfgdir)
	cd templates; $(cpiop) $(DESTDIR)$(cfgdir)
