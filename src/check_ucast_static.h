/*
 * Check format of network prefix
 */
#include <stdio.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#define IS_CLASSD(a)        ((((uint32_t)(a)) & 0x000000f0) == 0x000000e0)
#define IS_MULTICAST(a)     IS_CLASSD(a)
#define IS_BROADCAST(a)     ((((uint32_t)(a)) & 0xffffffff) == 0xffffffff)

#define IS_IPV6_MULTICAST(a) ((((uint32_t)(a)) & 0x000000ff) == 0x000000ff)


typedef struct
{
	uint8_t family;
	uint8_t bytelen;
	unsigned int plen;
	uint32_t data[4];
} inet_prefix;

void get_addr_1(inet_prefix *addr, const char *name, int family);
void err(const char *fmt, ...);

/*
static void get_addr_1(inet_prefix *addr, const char *name, int family)
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
*/
void err(const char *fmt, ...);
