#!/bin/bash
#

#
# Ref: http://blog.spinhirne.com/2016/09/the-ovn-load-balancer.html
#

source /vagrant/scripts/helper-functions

do_start_webserver () {
    set -e
    set -x
    VMNAME=$1
    NSNAME=$2
    
    mkdir -pv /tmp/www/${VMNAME}
    cd /tmp/www/${VMNAME}
    echo "i am ${VMNAME}" > ./index.html
    sudo ip netns exec ${NSNAME} nohup /usr/bin/python -m SimpleHTTPServer 8000 >log.txt 2>&1 &
}

# TODO: need a handy tool to convert 'vm' to the namespace
rpcsh -h compute1 -m do_start_webserver -- vm1 ns1
rpcsh -h compute2 -m do_start_webserver -- vm2 ns3

set -x

uuid=$(sudo ovn-nbctl create load_balancer vips:172.16.255.62="172.16.255.130,172.16.255.131")
echo $uuid

sudo ovn-nbctl set logical_switch inside load_balancer=$uuid

sudo ovn-nbctl get logical_switch inside load_balancer
