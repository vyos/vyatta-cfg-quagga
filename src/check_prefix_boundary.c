#include "check_ucast_static.h"

static void usage(void)
{
	fprintf(stderr, "Usage: check-prefix-boundary [-4|-6] address/prefix\n");
	exit(1);
}

static void get_prefix_1(inet_prefix *dst, char *arg, int family)
{
	char *slash, *endp;

	memset(dst, 0, sizeof(*dst));

	slash = strchr(arg, '/');
	if (!slash || slash[1] == '\0')
		err("Missing prefix length\n");
	*slash = 0;

	get_addr_1(dst, arg, family);

	dst->plen = strtoul(slash+1, &endp, 0);
	if (*endp != '\0')
		err("Invalid character in prefix length\n");

	if (dst->plen > 8 * dst->bytelen)
		err("Prefix length is too large\n");

	*slash = '/';
}

static void get_netmask(inet_prefix *msk, const inet_prefix *dst)
{
	int i, plen = dst->plen;

	memset(msk, 0, sizeof(*msk));
	msk->family = dst->family;
	msk->bytelen = dst->bytelen;

	for (i = 0; plen > 0 && i < dst->bytelen / sizeof(uint32_t); i++) {
		uint32_t m = (plen > 32) ? ~0 : htonl(~0 << (32 - plen));
		
		msk->data[i] = dst->data[i] & m;
		plen -= 32;
	}
}

int main(int argc, char **argv)
{
	int family = AF_UNSPEC;
    
	while (--argc) {
		char *arg = *++argv;
		inet_prefix dst, msk;

		if (arg[0] == '-') { 
			switch(arg[1]) {
			case '4':
				family = AF_INET;
				break;
			case '6':
				family = AF_INET6;
				break;
			default:
				usage();
			}
            continue;
        }

		get_prefix_1(&dst, arg, family);
		get_netmask(&msk, &dst);
		
		if (memcmp(msk.data, dst.data, dst.bytelen) != 0) {
			char buf[INET_ADDRSTRLEN];
			err("Prefix not on a natural network boundary."
			    "Did you mean %s?\n", 
			    inet_ntop(msk.family, msk.data, buf, sizeof buf));
		}

        /*
         * Macros to check for Mcast are based on:
         *
         *    Addr          dst.data
         * 224.1.2.2    ==> 0x030201e0
         * ff01:0203::  ==> 0x030201ff
         *
         */
        if (family == AF_INET) {
            if (IS_MULTICAST(dst.data[0])) {
                err("Invalid Prefix...Route cannot be Multicast\n");
            } 
            if (IS_BROADCAST(dst.data[0])) {
                err("Invalid Prefix...Route cannot be Broadcast\n");
            } 
        } else if (family == AF_INET6) {
            if (IS_IPV6_MULTICAST(dst.data[0])) {
                err("Invalid Prefix...Route cannot be IPv6 Multicast\n");
            } 
        }

	}

	return 0;
}
