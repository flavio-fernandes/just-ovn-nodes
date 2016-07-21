#!/bin/bash

#
# See "Locally attached networks" in tutorial/OVN-Tutorial.md.
#

source /vagrant/scripts/helper-functions

if test $(hostname --short) != "central" ; then
    echo >&2 "Run this command from central node"
    exit 2
fi

[ -f "$COMPUTE_NODES" ] ||
    { echo >&2 "bad ${COMPUTE_NODES}. Maybe setup-ovn-cluster.sh was not invoked?"; exit 1; }

do_map_provider_net () {
    echo "executing in $(hostname --short)"
    set -o xtrace
    sudo ovs-vsctl set open . external-ids:ovn-bridge-mappings=physnet1:br-provider
}

do_on_compute_nodes do_map_provider_net

set -o xtrace

# create 4 logical switches, which will be split into 2 vlan based networks
sudo ovn-nbctl ls-add provnet1-1
sudo ovn-nbctl ls-add provnet1-2
sudo ovn-nbctl ls-add provnet2-1
sudo ovn-nbctl ls-add provnet2-2

# add logical port to each of the 4 logical switches, that will be used as
# fake tenant ports. Based on the vlan tag that they are connected with,
# these ports will be logically separated, while sharing the same physnet1
for n in 1 2; do
    sudo ovn-nbctl lsp-add provnet1-$n provnet1-$n-port1
    sudo ovn-nbctl lsp-set-addresses provnet1-$n-port1 00:00:00:00:01:0$n
    sudo ovn-nbctl lsp-set-port-security provnet1-$n-port1 00:00:00:00:01:0$n

    sudo ovn-nbctl lsp-add provnet2-$n provnet2-$n-port1
    sudo ovn-nbctl lsp-set-addresses provnet2-$n-port1 00:00:00:00:02:0$n
    sudo ovn-nbctl lsp-set-port-security provnet2-$n-port1 00:00:00:00:02:0$n
done


# add localnet port to each of the 4 logical switches. The first 2 will be on
# vlan tag 100 and the other 2 will be using vlan tag 200
for n in 1 2; do
    sudo ovn-nbctl lsp-add provnet1-$n provnet1-$n-physnet1 "" 100
    sudo ovn-nbctl lsp-set-addresses provnet1-$n-physnet1 unknown
    sudo ovn-nbctl lsp-set-type provnet1-$n-physnet1 localnet
    sudo ovn-nbctl lsp-set-options provnet1-$n-physnet1 network_name=physnet1

    sudo ovn-nbctl lsp-add provnet2-$n provnet2-$n-physnet1 "" 200
    sudo ovn-nbctl lsp-set-addresses provnet2-$n-physnet1 unknown
    sudo ovn-nbctl lsp-set-type provnet2-$n-physnet1 localnet
    sudo ovn-nbctl lsp-set-options provnet2-$n-physnet1 network_name=physnet1
done

/vagrant/scripts/create-ns-port.sh compute1 provnet1-1-port1 00:00:00:00:01:01 1.0.0.1/24
/vagrant/scripts/create-ns-port.sh compute1 provnet1-2-port1 00:00:00:00:01:02 1.0.0.2/24

/vagrant/scripts/create-ns-port.sh compute1 provnet2-1-port1 00:00:00:00:02:01 2.0.0.1/24
/vagrant/scripts/create-ns-port.sh compute2 provnet2-2-port1 00:00:00:00:02:02 2.0.0.2/24
