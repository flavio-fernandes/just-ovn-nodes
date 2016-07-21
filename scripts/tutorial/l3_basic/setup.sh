#!/bin/bash

#
# See "Simple l3 routing setup"
#

set -o xtrace

# Create logical switches "ls1" and "ls2".
sudo ovn-nbctl ls-add ls1
sudo ovn-nbctl ls-add ls2

# Create logical ports on "ls1" and "ls2".
sudo ovn-nbctl lsp-add ls1 ls1-port1
sudo ovn-nbctl lsp-add ls2 ls2-port1

# Set a MAC address for each of the two logical ports.
sudo ovn-nbctl lsp-set-addresses ls1-port1 "00:00:00:00:00:01 1.0.0.1"
sudo ovn-nbctl lsp-set-addresses ls2-port1 "00:00:00:00:00:02 2.0.0.1"

# Set up port security for the two logical ports.  This ensures that
# the logical port mac address we have configured is the only allowed
# source and destination mac address for these ports.
sudo ovn-nbctl lsp-set-port-security ls1-port1 00:00:00:00:00:01
sudo ovn-nbctl lsp-set-port-security ls2-port1 00:00:00:00:00:02

# Create ports on the local OVS bridge, br-int.
## create-ns-port.sh <NODE> <OVN_LSP> <MAC> <IP/MASK> <IP_GW>
/vagrant/scripts/create-ns-port.sh compute1 ls1-port1 00:00:00:00:00:01 1.0.0.1/24 1.0.0.2
/vagrant/scripts/create-ns-port.sh compute2 ls2-port1 00:00:00:00:00:02 2.0.0.1/24 2.0.0.2

#---

# Add a logical router, so 1.0.0.1 can reach 2.0.0.1

sudo ovn-nbctl lr-add lr0

sudo ovn-nbctl lrp-add lr0 lr0p1 00:00:00:01:00:01 1.0.0.2/24
sudo ovn-nbctl -- lsp-add ls1 lr0p1-attachment \
               -- set Logical_Switch_Port lr0p1-attachment \
                  type=router \
                  options:router-port=lr0p1 \
                  addresses='"00:00:00:01:00:01 1.0.0.2"'

sudo ovn-nbctl lrp-add lr0 lr0p2 00:00:00:01:00:02 2.0.0.2/24
sudo ovn-nbctl -- lsp-add ls2 lr0p2-attachment \
               -- set Logical_Switch_Port lr0p2-attachment \
                  type=router \
                  options:router-port=lr0p2 \
                  addresses='"00:00:00:01:00:02 2.0.0.2"'
