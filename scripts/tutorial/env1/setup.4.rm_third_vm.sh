#!/bin/bash
#

#
# Adding a third vm to setup
# Reference: http://blog.spinhirne.com/2016/09/a-primer-on-ovn.html
#

set -o xtrace

/vagrant/scripts/remove-ns-port.sh compute2 sw0-vm3

sudo ovn-nbctl lsp-set-port-security sw0-vm3
sudo ovn-nbctl lsp-set-addresses sw0-vm3
sudo ovn-nbctl lsp-del sw0-vm3
