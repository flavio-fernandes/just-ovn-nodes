#!/bin/bash
#
#
# Simple two-port setup to demonstrate SFC
#

set -o xtrace

# Create two logical ports on "sw0" to be used by NFV1
sudo ovn-nbctl lsp-add sw0 sw0-port-nvf1-in
sudo ovn-nbctl lsp-add sw0 sw0-port-nvf1-out

# Create two logical ports on "sw0" to be used by NFV2
sudo ovn-nbctl lsp-add sw0 sw0-port-nvf2-in
sudo ovn-nbctl lsp-add sw0 sw0-port-nvf2-out

sudo ovn-nbctl lsp-set-addresses sw0-port-nvf1-in  00:00:00:00:11:01
sudo ovn-nbctl lsp-set-addresses sw0-port-nvf1-out 00:00:00:00:11:02
sudo ovn-nbctl lsp-set-port-security sw0-port-nvf1-in
sudo ovn-nbctl lsp-set-port-security sw0-port-nvf1-out

sudo ovn-nbctl lsp-set-addresses sw0-port-nvf2-in  00:00:00:00:12:01
sudo ovn-nbctl lsp-set-addresses sw0-port-nvf2-out 00:00:00:00:12:02
sudo ovn-nbctl lsp-set-port-security sw0-port-nvf2-in
sudo ovn-nbctl lsp-set-port-security sw0-port-nvf2-out

# Create a port chain
sudo ovn-nbctl lsp-chain-add  sw0  chain1  sw0-port2

# Create 2 port pairs (NFV1 and NFV2)
sudo ovn-nbctl lsp-pair-add sw0 sw0-port-nvf1-in sw0-port-nvf1-out nfv1ppair
sudo ovn-nbctl lsp-pair-add sw0 sw0-port-nvf2-in sw0-port-nvf2-out nfv2ppair

# Create 2 port groups and add them to chain1
# Use the offset param to control the order in which chain uses them
# in the xample below, let's make pgrp2 to be visited after pgrp1, even
# if we add it first to the chain
sudo ovn-nbctl lsp-pair-group-add  chain1  pgrp2  999
sudo ovn-nbctl lsp-pair-group-add  chain1  pgrp1  666

# Associate port pairs to groups
sudo ovn-nbctl lsp-pair-group-add-port-pair pgrp1 nfv1ppair
sudo ovn-nbctl lsp-pair-group-add-port-pair pgrp2 nfv2ppair

# Create chain classifiers
sudo ovn-nbctl acl-add sw0 from-lport 1000 \
     'inport == "sw0-port1" && ip' \
     sfc 'sfc-port-chain=chain1'

# bind ports that will be used by nvf1 and nvf2. It does not matter which
# compute node gets used, but make sure to also update 3.start_vnf_apps.sh
/vagrant/scripts/create-ns-port-pair.sh compute3 sw0-port-nvf1-in sw0-port-nvf1-out 00:00:00:00:11:01 00:00:00:00:11:02
/vagrant/scripts/create-ns-port-pair.sh compute1 sw0-port-nvf2-in sw0-port-nvf2-out 00:00:00:00:12:01 00:00:00:00:12:02


