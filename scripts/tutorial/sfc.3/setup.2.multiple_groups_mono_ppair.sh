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
# lsp-chain-add LSWITCH [LSP-CHAIN]
sudo ovn-nbctl lsp-chain-add sw0 chain1

# Create 2 port pairs, each using a single port
# lsp-pair-add LSWITCH LIN-PORT LOUT-PORT [LSP-PAIR-NAME]
sudo ovn-nbctl lsp-pair-add sw0 sw0-port-nvf1-inout sw0-port-nvf1-inout nfv1ppair
sudo ovn-nbctl lsp-pair-add sw0 sw0-port-nvf2-inout sw0-port-nvf2-inout nfv2ppair

# Create 2 port groups and add them to chain1
# lsp-pair-group-add LSP-CHAIN LSP-PAIR-GROUP-NAME
sudo ovn-nbctl lsp-pair-group-add chain1 pgrp1
sudo ovn-nbctl lsp-pair-group-add chain1 pgrp2

sudo ovn-nbctl lsp-pair-group-add-port-pair pgrp1 nfv1ppair
sudo ovn-nbctl lsp-pair-group-add-port-pair pgrp2 nfv2ppair

# Create chain classifier -- TODO: to be turned into ACL
# lflow-classifier-add LSP-CHAIN LIN-PORT [LFLOW-CLASSIFIER-NAME]
sudo ovn-nbctl lflow-classifier-add chain1 sw0-port1 classifier1

# Set destination port of classifier1
# lflow-classifier-set-logical-destination-port LFLOW_CLASSIFIER LDEST_PORT
sudo ovn-nbctl lflow-classifier-set-logical-destination-port classifier1 sw0-port2

# bind ports that will be used by nvf1 and nvf2
/vagrant/scripts/create-ns-port.sh compute3 sw0-port-nvf1-inout 00:00:00:00:11:01 '' ''
/vagrant/scripts/create-ns-port.sh compute3 sw0-port-nvf2-inout 00:00:00:00:12:01 '' ''
