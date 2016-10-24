#!/bin/bash

set -e
#set -x

## create-ns-port.sh -- a very basic script for creating ovs ports in a remote node
## that has ovs running

## examples: /vagrant/scripts/create-ns-port.sh compute1 12 00:00:00:00:00:12 1.2.3.4/24 1.2.3.254 br-ex
##           /vagrant/scripts/create-ns-port.sh compute1 13 '' dhcp
##           /vagrant/scripts/create-ns-port.sh compute1 14

source /vagrant/scripts/helper-functions

# Script Arguments:
# $1 - OVS_NODE -- hostname where ovs-switchd is running
# $2 - PORT_LOGICAL_ID -- the external-id attribute added to the newly created ovs port
# $3 - MAC_ADDRESS -- optional. can be '' or a string formatted as 'xx:xx:xx:xx:xx:xx'
# $4 - IP_ADDRESS -- optional. Can be '', 'dhcp', or the $ipAddress
# $5 - IP_GW -- optional. Can be '' or the $gwIpAddress
# $6 - OVS_BRIDGE -- optional. Default value is br-int
OVS_NODE=$1
PORT_LOGICAL_ID=$2
MAC_ADDRESS=$3
IP_ADDRESS=$4
IP_GW=$5
OVS_BRIDGE=$6

if [ -z "$MAC_ADDRESS" ] ; then MAC_ADDRESS=any ; fi
if [ -z "$IP_ADDRESS" ] ; then IP_ADDRESS=none ; fi
if [ -z "$IP_GW" ] ; then IP_GW=none ; fi

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

do_create_ns_port () {
    set -x

    ns_idx=$1
    logical_id=$2
    mac_addr=$3
    ip_addr=$4
    ip_gw=$5
    bridge=${6-br-int}

    ns="ns${ns_idx}"
    devname="tap${ns_idx}"

    sudo ip netns add $ns
    sudo ip link add "${devname}_l" type veth peer name "${devname}_c"

    sudo ovs-vsctl --may-exist add-port $bridge ${devname}_l -- \
        set Interface ${devname}_l external-ids:iface-id=$logical_id || \
    { echo >&2 "could not add ${devname}_l to $bridge" ; sudo ip link delete "${devname}_l" ; exit 1; }

    sudo ip link set "${devname}_l" up

    # attach port to namespace and rename to eth0
    sudo ip link set "${devname}_c" netns $ns
    sudo ip netns exec $ns ip link set dev "${devname}_c" name eth0

    if test X"$mac_addr" != Xany ; then
        [ -n "$mac_addr" ] && sudo ip netns exec $ns ip link set eth0 address $mac_addr
    fi

    sudo ip netns exec $ns ip link set dev eth0 up
    sudo ip netns exec $ns ip link set dev eth0 mtu 1440

    if test X"$ip_addr" = Xdhcp ; then
        sudo ip netns exec $ns dhclient -nw eth0
    else
	if test X"$ip_addr" != Xnone ; then
	    sudo ip netns exec $ns ip addr add $ip_addr dev eth0
	fi
    fi

    if test X"$ip_gw" != Xnone ; then
        sudo ip netns exec $ns ip route add default via "$ip_gw"
    fi
}

rpcsh -h $OVS_NODE -m do_create_ns_port -- $cnt $PORT_LOGICAL_ID $MAC_ADDRESS $IP_ADDRESS $IP_GW $OVS_BRIDGE
