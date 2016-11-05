#!/bin/bash
#
#
# Simple two-port setup to demonstrate SFC
#

# bind ports that will be used by nvf1
/vagrant/scripts/create-ns-port-pair.sh compute3 \
    sw0-port-nvf1-in sw0-port-nvf1-out \
    00:00:00:00:10:01 00:00:00:00:10:02

set -o xtrace

# Create a port chain
# lsp-chain-add              LSWITCH  [LSP-CHAIN]  last_hop_port
sudo ovn-nbctl lsp-chain-add   sw0    chain1       sw0-port2

# Create two logical ports on "sw0" to be used by NFV1
sudo ovn-nbctl lsp-add sw0 sw0-port-nvf1-in
sudo ovn-nbctl lsp-add sw0 sw0-port-nvf1-out

sudo ovn-nbctl lsp-set-addresses sw0-port-nvf1-in  00:00:00:00:10:01
sudo ovn-nbctl lsp-set-addresses sw0-port-nvf1-out 00:00:00:00:10:02

# Set up port security for the two logical ports.  This ensures that
# NFV1 will be allowed to see all packets, even the ones for L2 it
# does own
sudo ovn-nbctl lsp-set-port-security sw0-port-nvf1-in
sudo ovn-nbctl lsp-set-port-security sw0-port-nvf1-out

# Create a port pair
# lsp-pair-add              LSWITCH IN-PORT          OUT-PORT    [LSP-PAIR-NAME]
sudo ovn-nbctl lsp-pair-add  sw0    sw0-port-nvf1-in sw0-port-nvf1-out nfv1ppair

# Create a port group and add nfv1ppair to it
# lsp-pair-group-add              LSP-CHAIN GROUP-NAME [OFFSET]
sudo ovn-nbctl lsp-pair-group-add chain1    pgrp1

sudo ovn-nbctl lsp-pair-group-add-port-pair pgrp1  nfv1ppair

# Create chain classifier, via ACL.
# Match includes inport, and action is sfc. Options follow action and
# includes the chain that the sfc action is about.
#
sudo ovn-nbctl acl-add sw0 from-lport 1000 \
     'inport == "sw0-port1" && icmp4' \
     sfc 'sfc-port-chain=chain1 debugInfo=will_use_nfv1'

