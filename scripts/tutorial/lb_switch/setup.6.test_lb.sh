#!/bin/bash
#

#
# Ref: http://blog.spinhirne.com/2016/09/the-ovn-load-balancer.html
#

source /vagrant/scripts/helper-functions

do_poke_webserver () {
    ITER_ID=$1
    VIP=$2
    TCP_PORT=$3
    NS_NAME=$4
    
    # set -x
    echo -n "Iteration $ITER_ID: "
    sudo ip netns exec ${NS_NAME} curl --silent ${VIP}:${TCP_PORT}
}

for x in $(seq 10) ; do
    rpcsh -h compute1 -m do_poke_webserver -- $x 172.16.255.62 8000 ns2
done
