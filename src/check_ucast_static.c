#include "check_ucast_static.h"

void get_addr_1(inet_prefix *addr, const char *name, int family)
{
	memset(addr, 0, sizeof(*addr));

	if (strchr(name, ':')) {
		addr->family = AF_INET6;
		addr->bytelen = 16;
		if (family != AF_UNSPEC && family != AF_INET6)
			err("IPV6 address not allowed\n");

		if (inet_pton(AF_INET6, name, addr->data) <= 0)
			err("Invalid IPV6 address: %s\n", name);

		return;
	}

	addr->family = AF_INET;
	addr->bytelen = 4;
	if (family != AF_UNSPEC && family != AF_INET)
		err("IPV4 address not allowed\n");

	if (inet_pton(AF_INET, name, addr->data) <= 0)
		err("Invalid IPV4 address: %s\n", name);
	return;
}

void err(const char *fmt, ...)
{
	va_list ap;
	
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);

	exit(1);
}
