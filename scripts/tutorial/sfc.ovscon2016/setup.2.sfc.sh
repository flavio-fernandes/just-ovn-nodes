#!/bin/bash
#
#
# Simple SFC
#
#
#
#             VNF_B   VNF_C
#              | |      |
#    VM1 --------------------- VM2
#          |           |
#        VNF_A        VM3
#
#
#   VM1: 1.0.0.1   VM2: 1.0.0.2   VM3: 1.0.0.3
#
#   Chain 1_2:  from VM1 to VM2 ------- VNF_A, followed by VNF_B
#   Chain 1_3:  from VM1 to VM3 ------- VNF_C
#   Chain 2_1:  from VM2 to VM1 ------- VNF_A
#   Chain 2_3:  from VM2 to VM3 ------- VNF_B, followed by VNF_A
#   Chain 3_1:  from VM3 to VM1 ------- VNF_C
#
#   VNF_A: single port
#   VNF_B: input and output ports
#   VNF_C: single port
#
# Namespaces
# ns1 ==> compute1 ==> VM1
# ns2 ==> compute2 ==> VM2
# ns3 ==> compute2 ==> VM3
# ns4 ==> compute3 ==> VNF_A
# ns5 ==> compute3 ==> VNF_B
# ns6 ==> compute3 ==> VNF_C

set -o xtrace

# One logical port to be used by VNF_A
sudo ovn-nbctl lsp-add sw0 sw0-port-vnfa-inout

# Create two logical ports on "sw0" to be used by VNF_B
sudo ovn-nbctl lsp-add sw0 sw0-port-vnfb-in
sudo ovn-nbctl lsp-add sw0 sw0-port-vnfb-out

# One logical port to be used by VNF_C
sudo ovn-nbctl lsp-add sw0 sw0-port-vnfc-inout

sudo ovn-nbctl lsp-set-addresses sw0-port-vnfa-inout  00:00:00:00:11:01
sudo ovn-nbctl lsp-set-port-security sw0-port-vnfa-inout

sudo ovn-nbctl lsp-set-addresses sw0-port-vnfb-in  00:00:00:00:12:01
sudo ovn-nbctl lsp-set-addresses sw0-port-vnfb-out 00:00:00:00:12:02
sudo ovn-nbctl lsp-set-port-security sw0-port-vnfb-in
sudo ovn-nbctl lsp-set-port-security sw0-port-vnfb-out

sudo ovn-nbctl lsp-set-addresses sw0-port-vnfc-inout  00:00:00:00:13:01
sudo ovn-nbctl lsp-set-port-security sw0-port-vnfc-inout

# Create 3 port pairs (VNF_A, VNF_B and VNF_C)
sudo ovn-nbctl lsp-pair-add sw0 sw0-port-vnfa-inout sw0-port-vnfa-inout vnfa
sudo ovn-nbctl lsp-pair-add sw0 sw0-port-vnfb-in sw0-port-vnfb-out vnfb
sudo ovn-nbctl lsp-pair-add sw0 sw0-port-vnfc-inout sw0-port-vnfc-inout vnfc

# Create a port chains
sudo ovn-nbctl lsp-chain-add  sw0  chain1_2  sw0-port2
sudo ovn-nbctl lsp-chain-add  sw0  chain1_3  sw0-port3
sudo ovn-nbctl lsp-chain-add  sw0  chain2_1  sw0-port1
sudo ovn-nbctl lsp-chain-add  sw0  chain2_3  sw0-port3
sudo ovn-nbctl lsp-chain-add  sw0  chain3_1  sw0-port1

# Create port groups, which represent the hops of the chain
sudo ovn-nbctl lsp-pair-group-add  chain1_2  pg1_2_h1
sudo ovn-nbctl lsp-pair-group-add  chain1_2  pg1_2_h2
sudo ovn-nbctl lsp-pair-group-add  chain1_3  pg1_3
sudo ovn-nbctl lsp-pair-group-add  chain2_1  pg2_1
sudo ovn-nbctl lsp-pair-group-add  chain2_3  pg2_3_h1
sudo ovn-nbctl lsp-pair-group-add  chain2_3  pg2_3_h2
sudo ovn-nbctl lsp-pair-group-add  chain3_1  pg3_1

# Associate port pairs to groups
sudo ovn-nbctl lsp-pair-group-add-port-pair pg1_2_h1 vnfa 
sudo ovn-nbctl lsp-pair-group-add-port-pair pg1_2_h2 vnfb 
sudo ovn-nbctl lsp-pair-group-add-port-pair pg1_3    vnfc 
sudo ovn-nbctl lsp-pair-group-add-port-pair pg2_1    vnfa 
sudo ovn-nbctl lsp-pair-group-add-port-pair pg2_3_h1 vnfb 
sudo ovn-nbctl lsp-pair-group-add-port-pair pg2_3_h2 vnfa 
sudo ovn-nbctl lsp-pair-group-add-port-pair pg3_1    vnfc 

# Create chain classifiers via acl rules
sudo ovn-nbctl acl-add sw0 from-lport 1000 \
     'inport == "sw0-port1" && ip4.dst == 1.0.0.2' sfc 'sfc-port-chain=chain1_2'

sudo ovn-nbctl acl-add sw0 from-lport 1000 \
     'inport == "sw0-port1" && ip4.dst == 1.0.0.3' sfc 'sfc-port-chain=chain1_3'

sudo ovn-nbctl acl-add sw0 from-lport 1000 \
     'inport == "sw0-port2" && ip4.dst == 1.0.0.1' sfc 'sfc-port-chain=chain2_1'

sudo ovn-nbctl acl-add sw0 from-lport 1000 \
     'inport == "sw0-port2" && ip4.dst == 1.0.0.3' sfc 'sfc-port-chain=chain2_3'

sudo ovn-nbctl acl-add sw0 from-lport 1000 \
     'inport == "sw0-port3" && ip4.dst == 1.0.0.1' sfc 'sfc-port-chain=chain3_1'

# bind ports that will be used by vnfs
/vagrant/scripts/create-ns-port.sh      compute3 sw0-port-vnfa-inout 00:00:00:00:11:01 '' ''
/vagrant/scripts/create-ns-port-pair.sh compute3 sw0-port-vnfb-in sw0-port-vnfb-out 00:00:00:00:12:01 00:00:00:00:12:02
/vagrant/scripts/create-ns-port.sh      compute3 sw0-port-vnfc-inout 00:00:00:00:13:01 '' ''

