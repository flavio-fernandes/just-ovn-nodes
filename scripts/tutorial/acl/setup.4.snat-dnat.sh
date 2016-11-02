#!/bin/bash
#

#
# Ref: http://blog.spinhirne.com/2016/09/the-ovn-gateway-router.html
#

set -o xtrace

# # add a default route to edge1 router
# # the default gateway will connect edge1 to its nexhop outside the OVN
# # topology. In the diag at the datanet, that would be 10.127.0.128 instead
# # of 10.10.0.1
# sudo ovn-nbctl lr-route-add edge1 "0.0.0.0/0" 10.10.0.1

# create snat-dnat rule for vm1 & apply to edge1
sudo ovn-nbctl -- --id=@nat create nat type="dnat_and_snat" logical_ip=172.16.255.130 \
          external_ip=10.10.0.250 -- add logical_router edge1 nat @nat

# create snat-dnat rule for vm2 & apply to edge1
sudo ovn-nbctl -- --id=@nat create nat type="dnat_and_snat" logical_ip=172.16.255.131 \
          external_ip=10.10.0.251 -- add logical_router edge1 nat @nat

