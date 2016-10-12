#!/bin/bash
#

#
# Ref: http://blog.spinhirne.com/2016/09/an-introduction-to-ovn-routing.html
#

set -o xtrace

# create 2 logical switches
sudo ovn-nbctl ls-add inside
sudo ovn-nbctl ls-add dmz

# add the router
sudo ovn-nbctl lr-add tenant1

# create router port for the connection to dmz
sudo ovn-nbctl lrp-add tenant1 tenant1-dmz 02:ac:10:ff:01:29 172.16.255.129/26

# create the dmz switch port for connection to tenant1
sudo ovn-nbctl lsp-add dmz dmz-tenant1
sudo ovn-nbctl lsp-set-type dmz-tenant1 router
sudo ovn-nbctl lsp-set-addresses dmz-tenant1 02:ac:10:ff:01:29
sudo ovn-nbctl lsp-set-options dmz-tenant1 router-port=tenant1-dmz

# create router port for the connection to inside
sudo ovn-nbctl lrp-add tenant1 tenant1-inside 02:ac:10:ff:01:93 172.16.255.193/26

# create the inside switch port for connection to tenant1
sudo ovn-nbctl lsp-add inside inside-tenant1
sudo ovn-nbctl lsp-set-type inside-tenant1 router
sudo ovn-nbctl lsp-set-addresses inside-tenant1 02:ac:10:ff:01:93
sudo ovn-nbctl lsp-set-options inside-tenant1 router-port=tenant1-inside

## sudo ovn-nbctl show

# Add DHCP
sudo ovn-nbctl lsp-add dmz dmz-vm1
sudo ovn-nbctl lsp-set-addresses dmz-vm1 "02:ac:10:ff:01:30 172.16.255.130"
sudo ovn-nbctl lsp-set-port-security dmz-vm1 "02:ac:10:ff:01:30 172.16.255.130"

sudo ovn-nbctl lsp-add dmz dmz-vm2
sudo ovn-nbctl lsp-set-addresses dmz-vm2 "02:ac:10:ff:01:31 172.16.255.131"
sudo ovn-nbctl lsp-set-port-security dmz-vm2 "02:ac:10:ff:01:31 172.16.255.131"

sudo ovn-nbctl lsp-add inside inside-vm3
sudo ovn-nbctl lsp-set-addresses inside-vm3 "02:ac:10:ff:01:94 172.16.255.194"
sudo ovn-nbctl lsp-set-port-security inside-vm3 "02:ac:10:ff:01:94 172.16.255.194"

sudo ovn-nbctl lsp-add inside inside-vm4
sudo ovn-nbctl lsp-set-addresses inside-vm4 "02:ac:10:ff:01:95 172.16.255.195"
sudo ovn-nbctl lsp-set-port-security inside-vm4 "02:ac:10:ff:01:95 172.16.255.195"

## sudo ovn-nbctl show

dmzDhcp="$(sudo ovn-nbctl create DHCP_Options cidr=172.16.255.128/26 \
options="\"server_id\"=\"172.16.255.129\" \"server_mac\"=\"02:ac:10:ff:01:29\" \
       \"lease_time\"=\"3600\" \"router\"=\"172.16.255.129\"")"
echo $dmzDhcp

insideDhcp="$(sudo ovn-nbctl create DHCP_Options cidr=172.16.255.192/26 \
options="\"server_id\"=\"172.16.255.193\" \"server_mac\"=\"02:ac:10:ff:01:93\" \
          \"lease_time\"=\"3600\" \"router\"=\"172.16.255.193\"")"
echo $insideDhcp

sudo ovn-nbctl dhcp-options-list

sudo ovn-nbctl lsp-set-dhcpv4-options dmz-vm1 $dmzDhcp
sudo ovn-nbctl lsp-get-dhcpv4-options dmz-vm1

sudo ovn-nbctl lsp-set-dhcpv4-options dmz-vm2 $dmzDhcp
sudo ovn-nbctl lsp-get-dhcpv4-options dmz-vm2

sudo ovn-nbctl lsp-set-dhcpv4-options inside-vm3 $insideDhcp
sudo ovn-nbctl lsp-get-dhcpv4-options inside-vm3

sudo ovn-nbctl lsp-set-dhcpv4-options inside-vm4 $insideDhcp
sudo ovn-nbctl lsp-get-dhcpv4-options inside-vm4

/vagrant/scripts/create-ns-port.sh compute1 dmz-vm1 02:ac:10:ff:01:30 dhcp
/vagrant/scripts/create-ns-port.sh compute1 inside-vm3 02:ac:10:ff:01:94 dhcp

/vagrant/scripts/create-ns-port.sh compute2 dmz-vm2 02:ac:10:ff:01:31 dhcp
/vagrant/scripts/create-ns-port.sh compute2 inside-vm4 02:ac:10:ff:01:95 dhcp
