#!/bin/bash
#

set -o xtrace

# Create a logical switch named "sw0"
sudo ovn-nbctl ls-add sw0

# Create logical ports on "sw0"
sudo ovn-nbctl lsp-add sw0 sw0-port1
sudo ovn-nbctl lsp-add sw0 sw0-port2
sudo ovn-nbctl lsp-add sw0 sw0-port3

# Set a MAC address for each of the logical ports
sudo ovn-nbctl lsp-set-addresses sw0-port1 "00:00:00:00:00:01 1.0.0.1"
sudo ovn-nbctl lsp-set-addresses sw0-port2 "00:00:00:00:00:02 1.0.0.2"
sudo ovn-nbctl lsp-set-addresses sw0-port3 "00:00:00:00:00:03 1.0.0.3"

# Set up port security for the two logical ports
sudo ovn-nbctl lsp-set-port-security sw0-port1 "00:00:00:00:00:01 1.0.0.1"
sudo ovn-nbctl lsp-set-port-security sw0-port2 "00:00:00:00:00:02 1.0.0.2"
sudo ovn-nbctl lsp-set-port-security sw0-port3 "00:00:00:00:00:03 1.0.0.3"

# Bind ports by creating a namespace for each one of them
/vagrant/scripts/create-ns-port.sh compute1 sw0-port1 00:00:00:00:00:01 1.0.0.1/24
/vagrant/scripts/create-ns-port.sh compute2 sw0-port2 00:00:00:00:00:02 1.0.0.2/24
/vagrant/scripts/create-ns-port.sh compute2 sw0-port3 00:00:00:00:00:03 1.0.0.3/24
