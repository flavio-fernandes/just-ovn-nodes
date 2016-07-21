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

# create 4 logical switches.
# in each of the logical switches, add a pair of logical ports.
# the first of the pair, will be used as fake tenant ports.
# the second of the pair will connect the logical switch to the br-provider, using
# the localnet type
for n in 1 2 3 4; do
    sudo ovn-nbctl ls-add provnet1-$n

    sudo ovn-nbctl lsp-add provnet1-$n provnet1-$n-port1
    sudo ovn-nbctl lsp-set-addresses provnet1-$n-port1 00:00:00:00:00:0$n
    sudo ovn-nbctl lsp-set-port-security provnet1-$n-port1 00:00:00:00:00:0$n

    sudo ovn-nbctl lsp-add provnet1-$n provnet1-$n-physnet1
    sudo ovn-nbctl lsp-set-addresses provnet1-$n-physnet1 unknown
    sudo ovn-nbctl lsp-set-type provnet1-$n-physnet1 localnet
    sudo ovn-nbctl lsp-set-options provnet1-$n-physnet1 network_name=physnet1
done

#ovs-vsctl add-port br-int lport1 -- set Interface lport1 external_ids:iface-id=provnet1-1-port1
#ovs-vsctl add-port br-int lport2 -- set Interface lport2 external_ids:iface-id=provnet1-2-port1
#ovn-sbctl lsp-bind provnet1-3-port1 fakechassis
#ovn-sbctl lsp-bind provnet1-4-port1 fakechassis

/vagrant/scripts/create-ns-port.sh compute1 provnet1-1-port1 00:00:00:00:00:01 1.0.0.1/24
/vagrant/scripts/create-ns-port.sh compute1 provnet1-2-port1 00:00:00:00:00:02 1.0.0.2/24

/vagrant/scripts/create-ns-port.sh compute2 provnet1-3-port1 00:00:00:00:00:03 1.0.0.3/24
/vagrant/scripts/create-ns-port.sh compute2 provnet1-4-port1 00:00:00:00:00:04 1.0.0.4/24
