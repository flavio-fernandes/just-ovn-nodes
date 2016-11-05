
Basic SFC Demo -- OVS Conference 2016 -- November/2016
   http://sched.co/8aZE

Steps and pointers for testing the SFC functionality, using
reference implementation from John McDowall and friends.

A screencast of this demo is available here:
   https://youtu.be/VBFoAQP0Dhk

In order to get VMs going, refer to
   http://www.flaviof.com/blog2/post/main/just-ovn-nodes/

And check out this repo's sfc branch:
   git clone -b sfc https://github.com/flavio-fernandes/just-ovn-nodes.git

Make sure file .../provisioning/virtualbox.conf.yml
uses the following repo and branch:

   ovn_repo: https://github.com/doonhammer/ovs.git
   ovn_branch: sfc.v2

From there, simply 'vagrant up'

--

From central, start OVN cluster:

  vagrant ssh central
  /vagrant/scripts/setup-ovn-cluster.sh

then, run config scripts:

  cd /vagrant/scripts/tutorial/sfc.ovscon2016 && \
  ./setup.sh && ./setup.2.sfc.sh && ./setup.3.nfvapp.sh

Look at the chains and how packets are supposed to hit VNFs:

  head -22 /vagrant/scripts/tutorial/sfc.ovscon2016/setup.2.sfc.sh

From compute 3, start monitor of nvfapp logs:

  vagrant ssh compute3
  tail -F /tmp/nvfapp_logs/log_vnf_?.txt

From compute1, enter namespace created to represent 'vm1'
and send a ping to vm2:

  vagrant ssh compute1
  sudo ip netns exec ns1 ping -c 1 1.0.0.2

Look at output of logs in compute3 and verify that packet
hit the VNFs. If it worked, it should look similar to this:

  https://gist.github.com/708ad1c2429d1f60ebdc96668b7ab9ea

  **VM1 -> VM2 : VNF_A
  ==> /tmp/nvfapp_logs/log_vnf_a.txt <==
  From eth0: PACKET: 98 bytes, wire length 98 cap length 98 @ 2016-11-04 22:34:40.668598 +0000 UTC
  - Layer 1 (14 bytes) = Ethernet    {Contents=[..14..] Payload=[..84..] SrcMAC=00:00:00:00:00:01 DstMAC=00:00:00:00:00:02 EthernetType=IPv4 Length=0}
  - Layer 2 (20 bytes) = IPv4        {... Protocol=ICMPv4 Checksum=13852 SrcIP=1.0.0.1 DstIP=1.0.0.2 Options=[] Padding=[]}
  - Layer 3 (08 bytes) = ICMPv4      {Contents=[..8..] Payload=[..56..] TypeCode=EchoRequest Checksum=56867 Id=13181 Seq=1}

  **VM1 -> VM2 : VNF_B
  ==> /tmp/nvfapp_logs/log_vnf_b.txt <==
  From eth0: PACKET: 98 bytes, wire length 98 cap length 98 @ 2016-11-04 22:34:40.672293 +0000 UTC
  - Layer 1 (14 bytes) = Ethernet    {Contents=[..14..] Payload=[..84..] SrcMAC=00:00:00:00:00:01 DstMAC=00:00:00:00:00:02 EthernetType=IPv4 Length=0}
  - Layer 2 (20 bytes) = IPv4        {... Protocol=ICMPv4 Checksum=13852 SrcIP=1.0.0.1 DstIP=1.0.0.2 Options=[] Padding=[]}
  - Layer 3 (08 bytes) = ICMPv4      {Contents=[..8..] Payload=[..56..] TypeCode=EchoRequest Checksum=56867 Id=13181 Seq=1}

  **VM2 -> VM1 : VNF_A
  ==> /tmp/nvfapp_logs/log_vnf_a.txt <==
  From eth0: PACKET: 98 bytes, wire length 98 cap length 98 @ 2016-11-04 22:34:40.68511 +0000 UTC
  - Layer 1 (14 bytes) = Ethernet    {Contents=[..14..] Payload=[..84..] SrcMAC=00:00:00:00:00:02 DstMAC=00:00:00:00:00:01 EthernetType=IPv4 Length=0}
  - Layer 2 (20 bytes) = IPv4        {... Protocol=ICMPv4 Checksum=38141 SrcIP=1.0.0.2 DstIP=1.0.0.1 Options=[] Padding=[]}
  - Layer 3 (08 bytes) = ICMPv4      {Contents=[..8..] Payload=[..56..] TypeCode=EchoReply Checksum=58915 Id=13181 Seq=1}

Back in central VM's shell, use ovn-trace to follow the logical rules that cause packet to follow the chain
from VM1 ping to VM2, for example:

  https://gist.github.com/2b11f7ab7d15f44d1ecd881dd8d3b98f

  vagrant ssh central

  PKT_COMMON='&& eth.dst == 00:00:00:00:00:02 && eth.src == 00:00:00:00:00:01 && ip4.dst == 1.0.0.2 && ip4.src == 1.0.0.1 && ip.ttl == 64'
  PKT_PING="$PKT_COMMON && icmp4.type == 8 && icmp4.code == 0"

  PKT_IN='inport == "sw0-port1"'
  sudo ovn-trace sw0 "$PKT_IN $PKT_PING"

  PKT_IN='inport == "sw0-port-vnfa-inout"'
  sudo ovn-trace sw0 "$PKT_IN $PKT_PING"

  PKT_IN='inport == "sw0-port-vnfb-out"'
  sudo ovn-trace sw0 "$PKT_IN $PKT_PING"
