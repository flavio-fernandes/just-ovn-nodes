#!/bin/bash
#

source /vagrant/scripts/helper-functions

do_start_nfvapp () {
    set -e
    set -x
    VMNAME=$1
    NSNAME=$2
    APPNAME=$3

    mkdir -pv /tmp/nvfapp_logs/
    cd /tmp/nvfapp_logs/
    sudo ip netns exec ${NSNAME} nohup /vagrant/nfvapp/${APPNAME} >log_${VMNAME}.txt 2>&1 &
}

rpcsh -h compute3 -m do_start_nfvapp -- vnf_a ns4 nfvapp_one_dev
rpcsh -h compute3 -m do_start_nfvapp -- vnf_b ns5 nfvapp
rpcsh -h compute3 -m do_start_nfvapp -- vnf_c ns6 nfvapp_one_dev

