#!/bin/bash
#
#
# Simple two-port setup to demonstrate SFC
#

set -o xtrace

# Create a logical ports on "sw0" to be used by NFV1
sudo ovn-nbctl lsp-add sw0 sw0-port-nvf1-inout
sudo ovn-nbctl lsp-add sw0 sw0-port-nvf2-inout

sudo ovn-nbctl lsp-set-addresses sw0-port-nvf1-inout  00:00:00:00:11:01
sudo ovn-nbctl lsp-set-port-security sw0-port-nvf1-inout

sudo ovn-nbctl lsp-set-addresses sw0-port-nvf2-inout  00:00:00:00:12:01
sudo ovn-nbctl lsp-set-port-security sw0-port-nvf2-inout

# Create a port chain
sudo ovn-nbctl lsp-chain-add  sw0  chain1  sw0-port2

# Create 2 port pairs, each using a single port for in+out
sudo ovn-nbctl lsp-pair-add sw0 sw0-port-nvf1-inout sw0-port-nvf1-inout nfv1ppair
sudo ovn-nbctl lsp-pair-add sw0 sw0-port-nvf2-inout sw0-port-nvf2-inout nfv2ppair

# Create 2 port groups and add them to chain1
sudo ovn-nbctl lsp-pair-group-add chain1 pgrp1
sudo ovn-nbctl lsp-pair-group-add chain1 pgrp2

sudo ovn-nbctl lsp-pair-group-add-port-pair pgrp1 nfv1ppair
sudo ovn-nbctl lsp-pair-group-add-port-pair pgrp2 nfv2ppair

# Create chain classifiers
sudo ovn-nbctl acl-add sw0 from-lport 1000 \
     'inport == "sw0-port1" && ip' \
     sfc 'sfc-port-chain=chain1'

# bind ports that will be used by nvf1 and nvf2
/vagrant/scripts/create-ns-port.sh compute3 sw0-port-nvf1-inout 00:00:00:00:11:01 '' ''
/vagrant/scripts/create-ns-port.sh compute3 sw0-port-nvf2-inout 00:00:00:00:12:01 '' ''
