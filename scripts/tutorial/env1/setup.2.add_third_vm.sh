#!/bin/bash
#

#
# Adding a third vm to setup
# Reference: http://blog.spinhirne.com/2016/09/a-primer-on-ovn.html
#

set -o xtrace

sudo ovn-nbctl lsp-add sw0 sw0-vm3
sudo ovn-nbctl lsp-set-addresses sw0-vm3 02:ac:10:ff:00:33
sudo ovn-nbctl lsp-set-port-security sw0-vm3 02:ac:10:ff:00:33

/vagrant/scripts/create-ns-port.sh compute1 sw0-vm3 02:ac:10:ff:00:33 1.0.0.3/24

