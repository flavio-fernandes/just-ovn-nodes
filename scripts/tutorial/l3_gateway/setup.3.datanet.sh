#!/bin/bash
#

#
# Ref: http://blog.spinhirne.com/2016/09/the-ovn-gateway-router.html
#

source /vagrant/scripts/helper-functions

set -o xtrace

do_set_bridge_mappings () {
    set -x

    OVN_BRIDGE=$1
    OVS_BRIDGE=$2
    
    # create bridge mapping for ${IF_DEV}. map network name "dataNet" to br-provider
    sudo ovs-vsctl set Open_vSwitch . external-ids:ovn-bridge-mappings=${OVN_BRIDGE}:${OVS_BRIDGE}
}

# create new port on router 'edge1'
sudo ovn-nbctl lrp-add edge1 edge1-outside 02:0a:7f:00:01:29 10.10.0.100/25

# create new logical switch and connect it to edge1
sudo ovn-nbctl ls-add outside
sudo ovn-nbctl lsp-add outside outside-edge1
sudo ovn-nbctl lsp-set-type outside-edge1 router
sudo ovn-nbctl lsp-set-addresses outside-edge1 02:0a:7f:00:01:29
sudo ovn-nbctl lsp-set-options outside-edge1 router-port=edge1-outside

# bridge for eth2 is called br-provider

# create bridge mapping for eth2. map network name "dataNet" to br-provider
set +x
rpcsh -h compute3 -m do_set_bridge_mappings -- dataNet br-provider
set -x

# create localnet port on 'outside'. set the network name to "dataNet"
sudo ovn-nbctl lsp-add outside outside-localnet
sudo ovn-nbctl lsp-set-addresses outside-localnet unknown
sudo ovn-nbctl lsp-set-type outside-localnet localnet
sudo ovn-nbctl lsp-set-options outside-localnet network_name=dataNet

