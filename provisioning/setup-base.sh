#!/bin/sh

# Script Arguments:
# $1 - MTU
# $2 - ovn-db IP address
# $3 - ovn-db short name
# $4 - ovn-compute1 IP address
# $5 - ovn-compute1 short name
# $6 - ovn-compute2 IP address
# $7 - ovn-compute2 short name
# $8 - ovn-compute3 IP address
# $9 - ovn-compute3 short name
MTU=$1
OVN_DB_IP=$2
OVN_DB_NAME=$3
OVN_COMPUTE1_IP=$4
OVN_COMPUTE1_NAME=$5
OVN_COMPUTE2_IP=$6
OVN_COMPUTE2_NAME=$7
OVN_COMPUTE3_IP=$8
OVN_COMPUTE3_NAME=$9

echo export LC_ALL=en_US.UTF-8 >> ~/.bash_profile
echo export LANG=en_US.UTF-8 >> ~/.bash_profile

# FIXME(ff): uncomment update, but it will make provisioning slower
#echo -n "doing apt-get -qqy update..."
#DEBIAN_FRONTEND=noninteractive sudo apt-get -qqy update

# FIXME(mestery): By default, Ubuntu ships with /bin/sh pointing to
# the dash shell.
# ..
# ..
# The dots above represent a pause as you pick yourself up off the
# floor. This means the latest version of "install_docker.sh" to load
# docker fails because dash can't interpret some of it's bash-specific
# things. It's a bug in install_docker.sh that it relies on those and
# uses a shebang of /bin/sh, but that doesn't help us if we want to run
# docker and specifically Kuryr. So, this works around that.
sudo update-alternatives --install /bin/sh sh /bin/bash 100

# Configure MTU on VM interfaces. Also requires manually configuring the same MTU on
# the equivalent 'vboxnet' interfaces on the host.
sudo ip link set dev eth1 mtu $MTU
sudo ip link set dev eth2 mtu $MTU

sudo sh -c "echo \"$OVN_DB_IP $OVN_DB_NAME\" >> /etc/hosts"
sudo sh -c "echo \"$OVN_COMPUTE1_IP $OVN_COMPUTE1_NAME\" >> /etc/hosts"
sudo sh -c "echo \"$OVN_COMPUTE2_IP $OVN_COMPUTE2_NAME\" >> /etc/hosts"
sudo sh -c "echo \"$OVN_COMPUTE3_IP $OVN_COMPUTE3_NAME\" >> /etc/hosts"

# Non-interactive SSH setup
echo 'Host *' >> ~/.ssh/config
echo '    StrictHostKeyChecking no' >> ~/.ssh/config
chmod 600 ~/.ssh/config
sudo cp ~vagrant/.ssh/id_rsa /root/.ssh
sudo cp ~vagrant/.ssh/authorized_keys /root/.ssh
sudo cp ~vagrant/.ssh/config /root/.ssh/config

# Automatically make all ovn helper functions available on bash
cat <<EOT >> ~vagrant/.bash_profile

# Automatically added by vagrant provisioning, setup-base.sh
if [ -f /vagrant/provisioning/ovn-common-functions ]; then
  . /vagrant/provisioning/ovn-common-functions
fi
EOT
