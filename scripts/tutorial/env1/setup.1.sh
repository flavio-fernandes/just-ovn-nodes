#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# See "Simple two-port setup" in tutorial/OVN-Tutorial.md.
#

set -o xtrace

# Create a logical switch named "sw0"
sudo ovn-nbctl ls-add sw0

# Create two logical ports on "sw0".
sudo ovn-nbctl lsp-add sw0 sw0-port1
sudo ovn-nbctl lsp-add sw0 sw0-port2

# Set a MAC address for each of the two logical ports.
sudo ovn-nbctl lsp-set-addresses sw0-port1 00:00:00:00:00:01
sudo ovn-nbctl lsp-set-addresses sw0-port2 00:00:00:00:00:02

# Set up port security for the two logical ports.  This ensures that
# the logical port mac address we have configured is the only allowed
# source and destination mac address for these ports.
sudo ovn-nbctl lsp-set-port-security sw0-port1 00:00:00:00:00:01
sudo ovn-nbctl lsp-set-port-security sw0-port2 00:00:00:00:00:02

# Create ports on the local OVS bridge, br-int.  When ovn-controller
# sees these ports show up with an "iface-id" that matches the OVN
# logical port names, it associates these local ports with the OVN
# logical ports.  ovn-controller will then set up the flows necessary
# for these ports to be able to communicate each other as defined by
# the OVN logical topology.
#
# We will also give the ports their own ip address, so we can play with
# classic ping over the geneve tunnel between computes 1 and 2
/vagrant/scripts/create-ns-port.sh compute1 sw0-port1 00:00:00:00:00:01 1.0.0.1/24
/vagrant/scripts/create-ns-port.sh compute2 sw0-port2 00:00:00:00:00:02 1.0.0.2/24
