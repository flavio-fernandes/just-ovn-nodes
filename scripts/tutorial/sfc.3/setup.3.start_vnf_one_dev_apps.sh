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

    mkdir -pv /tmp/nvfapp_logs/
    cd /tmp/nvfapp_logs/
    sudo ip netns exec ${NSNAME} nohup /vagrant/nfvapp/nfvapp_one_dev >log_${VMNAME}.txt 2>&1 &
}

# TODO: need a handy tool to convert 'vm' to the namespace
rpcsh -h compute3 -m do_start_nfvapp -- vnf1 ns3
rpcsh -h compute3 -m do_start_nfvapp -- vnf2 ns4

