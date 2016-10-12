#!/bin/bash
#

#
# Move third vm to compute2
# Reference: http://blog.spinhirne.com/2016/09/a-primer-on-ovn.html
#

set -o xtrace

/vagrant/scripts/remove-ns-port.sh compute1 sw0-vm3
/vagrant/scripts/create-ns-port.sh compute2 sw0-vm3 02:ac:10:ff:00:33 1.0.0.3/24

