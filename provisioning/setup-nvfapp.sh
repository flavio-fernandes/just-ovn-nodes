#!/bin/bash

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

# Build nvfapp
cd /vagrant/nfvapp && go build nfvapp.go

