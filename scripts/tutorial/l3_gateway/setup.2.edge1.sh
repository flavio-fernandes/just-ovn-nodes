#!/bin/bash
#

#
# Ref: http://blog.spinhirne.com/2016/09/the-ovn-gateway-router.html
#

set -o xtrace

# create router edge1
sudo ovn-nbctl create Logical_Router name=edge1 options:chassis=compute3

# create a new logical switch for connecting the edge1 and tenant1 routers
sudo ovn-nbctl ls-add transit

# edge1 to the transit switch
sudo ovn-nbctl lrp-add edge1 edge1-transit 02:ac:10:ff:00:01 172.16.255.1/30
sudo ovn-nbctl lsp-add transit transit-edge1
sudo ovn-nbctl lsp-set-type transit-edge1 router
sudo ovn-nbctl lsp-set-addresses transit-edge1 02:ac:10:ff:00:01
sudo ovn-nbctl lsp-set-options transit-edge1 router-port=edge1-transit

# tenant1 to the transit switch
sudo ovn-nbctl lrp-add tenant1 tenant1-transit 02:ac:10:ff:00:02 172.16.255.2/30
sudo ovn-nbctl lsp-add transit transit-tenant1
sudo ovn-nbctl lsp-set-type transit-tenant1 router
sudo ovn-nbctl lsp-set-addresses transit-tenant1 02:ac:10:ff:00:02
sudo ovn-nbctl lsp-set-options transit-tenant1 router-port=tenant1-transit

# add static routes
sudo ovn-nbctl lr-route-add edge1 "172.16.255.128/25" 172.16.255.2
sudo ovn-nbctl lr-route-add tenant1 "0.0.0.0/0" 172.16.255.1

sudo ovn-sbctl show
