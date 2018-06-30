#!/bin/bash

set -x
set -o errexit

sudo apt install -y golang git

mkdir -pv /home/vagrant/go
echo "export GOPATH=/home/vagrant/go" >> /home/vagrant/.bash_profile
echo 'export PATH=$PATH:/home/vagrant/go/bin' >> /home/vagrant/.bash_profile

export GOPATH=/home/vagrant/go
export PATH=$PATH:/home/vagrant/go/bin

# Pcap dev headers might be necessary
sudo apt install -y libpcap-dev

# Get the gopacket package from GitHub
go get github.com/google/gopacket

cd /home/vagrant/go/src/github.com/google/gopacket && \
git checkout v1.1.12

# Build nvfapp
cd /vagrant/nfvapp && go build nfvapp.go
cd /vagrant/nfvapp && go build nfvapp_one_dev.go
