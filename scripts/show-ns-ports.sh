#!/bin/bash

set -e
#set -x

## show-ns-ports.sh -- a script for listing the namespace that correspond to a given logical switch port
## that was created via create-ns-port.sh

## examples: /vagrant/scripts/find-ns-port.sh

source /vagrant/scripts/helper-functions

declare -A CHASSIS
declare -A LSP_CHASSIS
declare -A LSP_ADDR

if test $(hostname --short) != "central" ; then
    echo >&2 "Run this command from central node"
    exit 2
fi

[ -f "$COMPUTE_NODES" ] ||
    { echo >&2 "bad ${COMPUTE_NODES}. Maybe setup-ovn-cluster.sh was not invoked?"; exit 1; }

grep --quiet "$OVS_NODE" $COMPUTE_NODES || \
    { echo >&2 "node $OVS_NODE is not a valid option"; exit 1; }

populate_chassis_hash () {
    for i in $(sudo ovn-sbctl -f csv -d bare --no-heading -- --columns=_uuid,host list chassis) ; do
        ## echo $i
        row=(${i//,/ })
        uuid=${row[0]} ; host=${row[1]}
        if [[ -n "$uuid" && -n "$host" ]] ; then
            CHASSIS+=(["$uuid"]="$host")
        fi
    done
}

populate_lsp_hash () {
    # translate spaces into "_" to keep separator from confusing iteration
    for i in $(sudo ovn-sbctl -f csv -d bare --no-heading -- --columns=logical_port,chassis,mac list port_binding | tr "[:blank:]" "_") ; do
        # echo $i
        row=(${i//,/ })
        logical_port=${row[0]} ; chassis_uuid=${row[1]} ; mac=${row[2]}
        if [ -n "$chassis_uuid" ] ; then
            host="${CHASSIS[$chassis_uuid]}"
            if [ -n "$host" ] ; then
                # echo "added $logical_port as $host to LSP_CHASSIS"
                LSP_CHASSIS+=(["$logical_port"]="$host")
                if [ -n "$mac" ] ; then
                    LSP_ADDR+=(["$logical_port"]="$mac")
                fi
            fi
        fi
    done
}

do_compute_lsp_show () {
    logical_port=$1
    IFS='_' read -ra addrs <<< "$2"
    # echo "this is $(hostname)"
    for addr_wanted in "${addrs[@]}"; do
        for ns in $(sudo ip netns) ; do
            ns_addr=$(sudo ip netns exec $ns ip -4 addr show eth0 | grep -oP "(?<=inet ).*(?=/)")
            if [ "$ns_addr" == "$addr_wanted" ] ; then
                echo "$ns in $(hostname --short) has eth0 with $ns_addr matches lsp $logical_port"
            fi
        done
    done
}

populate_chassis_hash

#for uuid in "${!CHASSIS[@]}" ; do
#    echo "CC $uuid => ${CHASSIS[$uuid]}"
#done

populate_lsp_hash

#for p in "${!LSP_CHASSIS[@]}" ; do
#    echo "LSP_CHASSIS $p => ${LSP_CHASSIS[$p]}"
#done

#for p in "${!LSP_ADDR[@]}" ; do
#    addrs=$(echo "${LSP_ADDR[$p]}" | tr "_" " ")
#    echo "LSP_ADDR $p => $addrs"
#done

for p in "${!LSP_ADDR[@]}" ; do
    addrs=$(echo "${LSP_ADDR[$p]}" | tr "_" " ")
    ovn_node="${LSP_CHASSIS[$p]}"
    ##echo "LSP_ADDR $p in node $ovn_node => $addrs"
    ovn_node_short="${ovn_node%%.*}"
    rpcsh -h $ovn_node_short -m do_compute_lsp_show -- $p ${LSP_ADDR[$p]}
done
