#include "check_ucast_static.h"

static void usage(void)
{
	fprintf(stderr, "Usage: check_next_hop [-4|-6] address\n");
	exit(1);
}

static void get_prefix_1(inet_prefix *dst, char *arg, int family)
{

	memset(dst, 0, sizeof(*dst));
	get_addr_1(dst, arg, family);

}

int main(int argc, char **argv)
{
	int family = AF_UNSPEC;
    
	while (--argc) {
		char *arg = *++argv;
		inet_prefix dst;

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
                err("Invalid next_hop...next_hop cannot be multicast\n");
            } 
            if (IS_BROADCAST(dst.data[0])) {
                err("Invalid next_hop...next_hop cannot be broadcast\n");
            } 
        } else if (family == AF_INET6) {
            if (IS_IPV6_MULTICAST(dst.data[0])) {
                err("Invalid next_hop...next_hop cannot be IPv6 multicast\n");
            } 
        }

	}

	return 0;
}
