#!/bin/bash
#

#
# Simple two-port setup to demonstrate SFC
#

source /vagrant/scripts/helper-functions

do_start_nfvapp () {
    set -e
    set -x
    VMNAME=$1
    NSNAME=$2

    mkdir -pv /tmp/nvfapp.log
    cd /tmp/nvfapp.log
    sudo ip netns exec ${NSNAME} nohup /vagrant/nfvapp/nfvapp >log.txt 2>&1 &
}

# TODO: need a handy tool to convert 'vm' to the namespace
rpcsh -h compute3 -m do_start_nfvapp -- nvfvm ns3


