#!/bin/bash

set -e
#set -x

## remove-ns-port.sh -- reverse create-ns-port.sh

## example: /vagrant/scripts/create-ns-port.sh compute1 12

source /vagrant/scripts/helper-functions

# Script Arguments:
# $1 - OVS_NODE -- hostname where ovs-switchd is running
# $2 - PORT_LOGICAL_ID -- the external-id attribute added to the ovs port
OVS_NODE=$1
PORT_LOGICAL_ID=$2

if test $(hostname --short) != "central" ; then
    echo >&2 "Run this command from central node"
    exit 2
fi

[ -f "$COMPUTE_NODES" ] ||
    { echo >&2 "bad ${COMPUTE_NODES}. Maybe setup-ovn-cluster.sh was not invoked?"; exit 1; }

grep --quiet "$OVS_NODE" $COMPUTE_NODES || \
    { echo >&2 "node $OVS_NODE is not a valid option"; exit 1; }

do_remove_ns_port () {
    set -x

    logical_id=$1

    # figure out the namespace that contains the logical port
    OVS_IF_INFO=$(sudo ovs-vsctl -f csv --data=bare \
                  --columns=name,external_ids,ofport,mac_in_use \
                  list Interface \
                  | grep $logical_id | head -1)

    if test X"$OVS_IF_INFO" = X ; then
        echo >&2 "could not locate logical port $logical_id in $(hostname --short)"
        exit 2
    fi
    # echo "$(hostname --short) found info $OVS_IF_INFO"

    PHYS_DEV=$(echo "$OVS_IF_INFO" | awk 'BEGIN { FS = "," } ; { print $1 }')
    ns_idx=$(echo $PHYS_DEV | grep -oP "(?<=tap)[\d]+(?=_)")

    ns="ns${ns_idx}"
    devname="tap${ns_idx}"

    if test X"$ns" = X ; then
        echo >&2 "could not locate logical port $logical_id in $OVS_IF_INFO for $(hostname --short)"
        exit 2
    fi
    # echo "$(hostname --short) found info $logical_id in namespace $ns"

    sudo ip netns exec $ns ip link set dev eth0 down

    # de-attach port from namespace
    sudo ip netns exec $ns ip link set dev eth0 name "${devname}_c"
    sudo ip netns exec $ns ip link set "${devname}_c" netns 1

    sudo ip link set "${devname}_l" down
    sudo ovs-vsctl --if-exists del-port $bridge ${devname}_l

    sudo ip link del "${devname}_c"
    ## sudo ip link del "${devname}_l"

    sudo ip netns delete $ns
}

rpcsh -h $OVS_NODE -m do_remove_ns_port -- $PORT_LOGICAL_ID
