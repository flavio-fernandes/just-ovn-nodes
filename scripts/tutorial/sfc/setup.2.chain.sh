#!/bin/bash
#
#
# Simple two-port setup to demonstrate SFC
#

# bind ports that will be used by nvf1
/vagrant/scripts/create-ns-port-pair.sh compute3 sw0-port-nvf1-in sw0-port-nvf1-out 00:00:00:00:10:01 00:00:00:00:10:02

set -o xtrace

# Create a port chain
# lsp-chain-add LSWITCH [LSP-CHAIN]
sudo ovn-nbctl lsp-chain-add sw0 chain1

# Create two logical ports on "sw0" to be used by NFV1
sudo ovn-nbctl lsp-add sw0 sw0-port-nvf1-in
sudo ovn-nbctl lsp-add sw0 sw0-port-nvf1-out

sudo ovn-nbctl lsp-set-addresses sw0-port-nvf1-in  00:00:00:00:10:01
sudo ovn-nbctl lsp-set-addresses sw0-port-nvf1-out 00:00:00:00:10:02
#sudo ovn-nbctl lsp-set-port-security sw0-port-nvf1-in  00:00:00:00:10:01
#sudo ovn-nbctl lsp-set-port-security sw0-port-nvf1-out 00:00:00:00:10:02
sudo ovn-nbctl lsp-set-port-security sw0-port-nvf1-in
sudo ovn-nbctl lsp-set-port-security sw0-port-nvf1-out

# Create a port pair
# lsp-pair-add LSWITCH LIN-PORT LOUT-PORT [LSP-PAIR-NAME]
sudo ovn-nbctl lsp-pair-add sw0 sw0-port-nvf1-in sw0-port-nvf1-out nfv1ppair

# Create a port group
# lsp-pair-group-add LSP-CHAIN LSP-PAIR-GROUP-NAME
sudo ovn-nbctl lsp-pair-group-add chain1 pgrp1
sudo ovn-nbctl lsp-pair-group-add-port-pair pgrp1 nfv1ppair

# Create chain classifier -- TODO: to be turned into ACL
# lflow-classifier-add LSP-CHAIN LIN-PORT [LFLOW-CLASSIFIER-NAME]
sudo ovn-nbctl lflow-classifier-add chain1 sw0-port1 classifier1

# Set destination port of classifier1
# lflow-classifier-set-logical-destination-port LFLOW_CLASSIFIER LDEST_PORT
sudo ovn-nbctl lflow-classifier-set-logical-destination-port classifier1 sw0-port2

