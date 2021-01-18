#!/usr/bin/env python3

import sys
import subprocess

import vyos.config


base_path = "protocols rpki "

def create_cache(c, cache):
    new_port = c.return_value(base_path + "cache {0} port".format(cache))
    new_addr = c.return_value(base_path + "cache {0} address".format(cache))
    new_pref = c.return_value(base_path + "cache {0} preference".format(cache))

    ssh = False
    if c.exists(base_path + "cache {0} ssh".format(cache)):
        ssh = True
        new_user = c.return_value(base_path + "cache {0} ssh username".format(cache))
        new_pubkey = c.return_value(base_path + "cache {0} ssh public-key-file".format(cache))
        new_privkey = c.return__value(base_path + "cache {0} ssh private-key-file".format(cache))
        new_known_hosts = c.return_value(base_path + "cache {0} ssh known-hosts-file".format(cache))

        if (not new_user) or (not new_pubkey) or (not new_privkey) or (not new_known_hosts):
            print("If SSH is used for RPKI cache, username, public/private keys, and known hosts file must be defined")
            sys.exit(1)

    if (not new_addr) or (not new_port):
        print("Address and port must be defined for RPKI cache servers")
        sys.exit(1)

    if not new_pref:
        new_pref = 1

    if ssh:
        subprocess.call(""" vtysh -c 'conf t' -c 'rpki' -c 'rpki cache {0} {1} {2} {3} {4} {5} preference {6}' """.format(new_addr, new_port, new_user, new_privkey, new_pubkey, new_known_hosts, new_pref), shell=True)
    else:
        subprocess.call(""" vtysh -c 'conf t' -c 'rpki' -c 'rpki cache {0} {1} preference {2}' """.format(new_addr, new_port, new_pref), shell=True)

def delete_cache(c, cache):
    ssh = False
    port = c.return_effective_value(base_path + "cache {0} port".format(cache))
    addr = c.return_effective_value(base_path + "cache {0} address".format(cache))
    pref = c.return_effective_value(base_path + "cache {0} preference".format(cache))

    if not pref:
        pref = 1

    if c.exists_effective(base_path + "cache {0} ssh".format(cache)):
        ssh = True
        user = c.return_effective_value(base_path + "cache {0} ssh username".format(cache))
        pubkey = c.return_effective_value(base_path + "cache {0} ssh public-key-file".format(cache))
        privkey = c.return_effective_value(base_path + "cache {0} ssh private-key-file".format(cache))
        known_hosts = c.return_effective_value(base_path + "cache {0} ssh known-hosts-file".format(cache))

        if ssh:
            subprocess.call(""" vtysh -c 'conf t' -c 'rpki' -c 'no rpki cache {0} {1} {2} {3} {4} {5} preference {6}' """.format(addr, port, user, privkey, pubkey, known_hosts, pref), shell=True)

    else:
        subprocess.call(""" vtysh -c 'conf t' -c 'rpki' -c 'no rpki cache {0} {1} preference {2}' """.format(addr, port, pref), shell=True)


config = vyos.config.Config()

caches = config.list_nodes(base_path + "cache")
orig_caches = config.list_effective_nodes(base_path + "cache")

# RPKI caches can only be manipulated when RPKI is stopped
print("Stopping RPKI")
subprocess.call(""" vtysh -c 'rpki stop' """, shell=True)

if not caches:
    for cache in orig_caches:
        delete_cache(config, cache)
else:
    for cache in caches:
        if cache in orig_caches:
            delete_cache(config, cache)
        create_cache(config, cache)

    for cache in orig_caches:
        if not cache in caches:
            # No longer exists
            delete_cache(config, cache)

if caches:
    print("Starting RPKI")
    subprocess.call(""" vtysh -c 'rpki start' """, shell=True)

