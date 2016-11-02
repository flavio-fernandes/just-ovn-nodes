#!/bin/bash
#

#
# Ref: http://blog.spinhirne.com/2016/09/the-ovn-gateway-router.html
#

set -o xtrace

# default drop
sudo ovn-nbctl acl-add dmz to-lport 900 "outport == \"dmz-vm1\" && ip" drop
sudo ovn-nbctl acl-add dmz to-lport 900 "outport == \"dmz-vm2\" && ip" drop

# allow all ip trafficand allowing related connections back in
sudo ovn-nbctl acl-add dmz from-lport 1000 "inport == \"dmz-vm1\" && ip" allow-related
sudo ovn-nbctl acl-add dmz from-lport 1000 "inport == \"dmz-vm2\" && ip" allow-related

# allow tcp 443 in and related connections back out
sudo ovn-nbctl acl-add dmz to-lport 1000 "outport == \"dmz-vm1\" && tcp.dst == 443" allow-related
sudo ovn-nbctl acl-add dmz to-lport 1000 "outport == \"dmz-vm2\" && tcp.dst == 443" allow-related


# create an address set for the dmz servers. they fall within a common /31
sudo ovn-nbctl create Address_Set name=dmz addresses=\"172.16.255.130/31\"

# allow from dmz on 3306
sudo ovn-nbctl acl-add inside to-lport 1000 'outport == "inside-vm3" && ip4.src == $dmz && tcp.dst == 3306' allow-related
sudo ovn-nbctl acl-add inside to-lport 1000 'outport == "inside-vm4" && ip4.src == $dmz && tcp.dst == 3306' allow-related

# default drop
sudo ovn-nbctl acl-add inside to-lport 900 "outport == \"inside-vm3\" && ip" drop
sudo ovn-nbctl acl-add inside to-lport 900 "outport == \"inside-vm4\" && ip" drop

