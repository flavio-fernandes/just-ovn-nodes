#!/bin/bash

set -e
#set -x

## create-ns-port-pair.sh -- a very basic script for creating a pair of ovs ports in a remote node
## that has ovs running. These ports are going to be scoped in a network namespace.

## examples: /vagrant/scripts/create-ns-port-pair.sh compute1 lp1 lp2 00:00:00:00:00:12 00:00:00:00:00:13 br-provider
##           /vagrant/scripts/create-ns-port-pair.sh compute1 lp1 lp2 '' 00:00:00:00:00:13

source /vagrant/scripts/helper-functions

# Script Arguments:
# $1 - OVS_NODE -- hostname where ovs-switchd is running
# $2 - PORT1_LOGICAL_ID -- the external-id attribute added to the newly created ovs port1
# $3 - PORT2_LOGICAL_ID -- the external-id attribute added to the newly created ovs port2
# $4 - MAC_ADDRESS1 -- optional. can be '' or a string formatted as 'xx:xx:xx:xx:xx:xx'
# $5 - MAC_ADDRESS2 -- optional. can be '' or a string formatted as 'xx:xx:xx:xx:xx:xx'
# $6 - OVS_BRIDGE -- optional. Default value is br-int
OVS_NODE=$1
PORT1_LOGICAL_ID=$2
PORT2_LOGICAL_ID=$3
MAC_ADDRESS1=$4
MAC_ADDRESS2=$5
OVS_BRIDGE=$6

if [ -z "$MAC_ADDRESS1" ] ; then MAC_ADDRESS1=any ; fi
if [ -z "$MAC_ADDRESS2" ] ; then MAC_ADDRESS2=any ; fi

if test $(hostname --short) != "central" ; then
    echo >&2 "Run this command from central node"
    exit 2
fi

[ -f "$COMPUTE_NODES" ] ||
    { echo >&2 "bad ${COMPUTE_NODES}. Maybe setup-ovn-cluster.sh was not invoked?"; exit 1; }

grep --quiet "$OVS_NODE" $COMPUTE_NODES || \
    { echo >&2 "node $OVS_NODE is not a valid option"; exit 1; }

cnt=$(get_next_counter_value)
{ [ -z "$cnt" ] || [ $((cnt + 1)) -eq 1 ]; } && \
    { echo >&2 "got invalid value to be used as unique namespace id: \'$cnt\'"; exit 1; }

do_create_ns_port_pair () {
    set -x

    ns_idx=$1
    logical_id1=$2
    logical_id2=$3
    mac_addr1=$4
    mac_addr2=$5
    bridge=${6-br-int}

    ns="ns${ns_idx}"
    dev1name="tap${ns_idx}_0"
    dev2name="tap${ns_idx}_1"

    sudo ip netns add $ns
    sudo ip link add "${dev1name}_l" type veth peer name "${dev1name}_c"
    sudo ip link add "${dev2name}_l" type veth peer name "${dev2name}_c"

    sudo ovs-vsctl --may-exist add-port $bridge ${dev1name}_l -- \
        set Interface ${dev1name}_l external-ids:iface-id=$logical_id1 || \
    { echo >&2 "could not add ${dev1name}_l to $bridge" ; sudo ip link delete "${dev1name}_l" ; exit 1; }
    sudo ip link set "${dev1name}_l" up

    sudo ovs-vsctl --may-exist add-port $bridge ${dev2name}_l -- \
         set Interface ${dev2name}_l external-ids:iface-id=$logical_id2 || \
    { echo >&2 "could not add ${dev2name}_l to $bridge" ; sudo ip link delete "${dev2name}_l" ; exit 1; }
    sudo ip link set "${dev2name}_l" up

    # attach port1 to namespace and rename to eth0
    sudo ip link set "${dev1name}_c" netns $ns
    sudo ip netns exec $ns ip link set dev "${dev1name}_c" name eth0

    # attach port2 to namespace and rename to eth1
    sudo ip link set "${dev2name}_c" netns $ns
    sudo ip netns exec $ns ip link set dev "${dev2name}_c" name eth1

    if test X"$mac_addr1" != Xany ; then
        [ -n "$mac_addr1" ] && sudo ip netns exec $ns ip link set eth0 address $mac_addr1
    fi
    if test X"$mac_addr2" != Xany ; then
        [ -n "$mac_addr2" ] && sudo ip netns exec $ns ip link set eth1 address $mac_addr2
    fi

    for devx in eth0 eth1; do
        sudo ip netns exec $ns ip link set dev $devx up
        sudo ip netns exec $ns ip link set dev $devx mtu 1440
    done
}

rpcsh -h $OVS_NODE -m do_create_ns_port_pair -- $cnt $PORT1_LOGICAL_ID $PORT2_LOGICAL_ID $MAC_ADDRESS1 $MAC_ADDRESS2 $OVS_BRIDGE
