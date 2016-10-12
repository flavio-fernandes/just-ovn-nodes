#!/bin/bash
#

#
# Ref: http://blog.spinhirne.com/2016/09/the-ovn-gateway-router.html
#

set -o xtrace

# create snat rule which will nat to the edge1-outside interface
sudo ovn-nbctl -- --id=@nat create nat type="snat" logical_ip=172.16.255.128/25 \
          external_ip=10.10.0.100 -- add logical_router edge1 nat @nat

# add a default route to edge1 router
# the default gateway will connect edge1 to its nexhop outside the OVN
# topology. In the diag at the datanet, that would be 10.127.0.128 instead
# of 10.10.0.1
sudo ovn-nbctl lr-route-add edge1 "0.0.0.0/0" 10.10.0.1

